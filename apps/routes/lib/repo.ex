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
    all
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
    types
    |> Enum.flat_map(&by_type/1)
  end
  def by_type(type) do
    all
    |> Enum.filter(fn
      %{type: ^type} -> true
      _ -> false
    end)
  end

  @doc """

  Given a stop ID, returns the list of routes which stop there.

  """
  @spec by_stop(String.t) :: [Routes.Route.t]
  def by_stop(stop_id) do
    cache stop_id, fn stop_id ->
      stop_id
      |> V3Api.Routes.by_stop
      |> handle_response
    end
  end

  @doc """

  Given a route_id, returns a map with the headsigns for trips in the given
  directions (by direction_id).

  """
  @spec headsigns(String.t) :: %{0 => [String.t], 1 => [String.t]}
  def headsigns(id) do
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
  defp hidden_routes(_), do: false

  defp parse_json(%JsonApi.Item{id: id, attributes: attributes}) do
    %Routes.Route{
      id: id,
      type: attributes["type"],
      name: name(attributes),
      key_route?: key_route?(attributes["description"])
    }
  end

  defp name(%{"type" => 3, "short_name" => short_name}), do: short_name
  defp name(%{"short_name" => short_name, "long_name" => ""}), do: short_name
  defp name(%{"long_name" => long_name}), do: long_name

  defp key_route?("Key Bus Route (Frequent Service)"), do: true
  defp key_route?("Rapid Transit"), do: true
  defp key_route?(_), do: false
end
