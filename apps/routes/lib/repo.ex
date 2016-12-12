defmodule Routes.Repo do
  use RepoCache, ttl: :timer.hours(24)

  @doc """

  Returns a list of all the routes

  """
  @spec all() :: [Routes.Route.t]
  def all do
    cache [], fn _ ->
      V3Api.Routes.all
      |> handle_response
    end
  end

  @doc """

  Returns a single route by ID

  """
  @spec get(String.t) :: Routes.Route.t | nil
  def get(id) do
    all()
    |> Enum.find(fn
      %{id: ^id} -> true
      _ -> false
    end)
  end

  @doc """

  Given a route_type (or list of route types), returns the list of routes matching that type.

  """
  @spec by_type([0..4] | 0..4) :: [Routes.Route.t]
  def by_type(types) when is_list(types) do
    all()
    |> Enum.filter(fn %{type: type} ->
      type in types
    end)
  end
  def by_type(type) do
    all()
    |> Enum.filter(&match?(%{type: ^type}, &1))
  end

  @doc """

  Given a stop ID, returns the list of routes which stop there.

  """
  @spec by_stop(String.t) :: [Routes.Route.t]
  def by_stop(stop_id, opts \\ []) do
    {:ok, routes} = cache {stop_id, opts}, fn {stop_id, opts} ->
      {:ok, stop_id
      |> V3Api.Routes.by_stop(opts)
      |> handle_response
      }
    end
    routes
  end

  @doc """

  Given a route_id, returns a map with the headsigns for trips in the given
  directions (by direction_id).

  """
  @spec headsigns(String.t) :: %{0 => [String.t], 1 => [String.t]}
  def headsigns(id) do
    cache id, fn id ->
      id
      |> V3Api.Trips.by_route
      |> (fn api -> api.data end).()
      |> do_headsigns
    end
  end

  def do_headsigns(routes) do
    routes
    |> Enum.flat_map(&direction_headsign_pair_from_trip/1)
    |> Enum.group_by(&(elem(&1, 0)))
    |> Map.new(fn {key, value_pairs} ->
      {key, value_pairs
      |> Enum.map(&(elem(&1, 1)))
      |> order_by_frequency}
    end)
    |> Map.put_new(0, []) # make sure there are default values
    |> Map.put_new(1, [])
  end

  defp handle_response(%{data: data}) do
    data
    |> Enum.reject(&hidden_routes/1)
    |> Enum.map(&parse_json/1)
  end

  defp hidden_routes(%{id: "746"}), do: true
  defp hidden_routes(%{id: "2427"}), do: true
  defp hidden_routes(%{id: "3233"}), do: true
  defp hidden_routes(%{id: "3738"}), do: true
  defp hidden_routes(%{id: "4050"}), do: true
  defp hidden_routes(%{id: "627"}), do: true
  defp hidden_routes(%{id: "725"}), do: true
  defp hidden_routes(%{id: "8993"}), do: true
  defp hidden_routes(%{id: "116117"}), do: true
  defp hidden_routes(%{id: "214216"}), do: true
  defp hidden_routes(%{id: "441442"}), do: true
  defp hidden_routes(%{id: "9701"}), do: true
  defp hidden_routes(%{id: "9702"}), do: true
  defp hidden_routes(%{id: "9703"}), do: true
  defp hidden_routes(%{id: "Logan-" <> _}), do: true
  defp hidden_routes(%{id: "CapeFlyer"}), do: true
  defp hidden_routes(_), do: false

  defp parse_json(%JsonApi.Item{id: id, attributes: attributes}) do
    %Routes.Route{
      id: id,
      type: attributes["type"],
      name: name(attributes),
      key_route?: key_route?(name(attributes), attributes["description"])
    }
  end

  defp name(%{"type" => 3, "short_name" => short_name}), do: short_name
  defp name(%{"short_name" => short_name, "long_name" => ""}), do: short_name
  defp name(%{"long_name" => long_name}), do: long_name

  defp key_route?(_, "Key Bus Route (Frequent Service)"), do: true
  defp key_route?(name, "Rapid Transit") when name != "Mattapan Trolley", do: true
  defp key_route?(_, _), do: false

  defp direction_headsign_pair_from_trip(%JsonApi.Item{attributes: %{"headsign" => ""}}) do
    # empty headsign, don't count it for the pair
    []
  end
  defp direction_headsign_pair_from_trip(%JsonApi.Item{attributes: attributes}) do
    [{attributes["direction_id"], attributes["headsign"]}]
  end

  defp order_by_frequency(enum) do
    # the complicated function in the middle collapses some lengths which are
    # close together and allows us to instead sort by the name.  For example,
    # on the Red line, Braintree has 710 trips, Ashmont has 709.  The
    # division by two with a floor makes them both -354 and so equal.  We
    # divide by -2 so that the ordering by count is large to small, but the
    # name ordering is small to large.
    enum
    |> Enum.group_by(&(&1))
    |> Enum.sort_by(fn {value, values} -> {
      values
      |> length
      |> (fn v -> Float.floor(v / -2) end).(), value}
    end)
    |> Enum.map(&(elem(&1, 0)))
  end
end
