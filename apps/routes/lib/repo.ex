defmodule Routes.Repo do
  use RepoCache, ttl: :timer.hours(24)

  import Routes.Parser

  @doc """

  Returns a list of all the routes

  """
  @spec all() :: [Routes.Route.t]
  def all do
    case cache [], fn _ ->
      result = handle_response(V3Api.Routes.all)
      for {:ok, routes} <- [result],
          route <- routes do
        ConCache.put(__MODULE__, {:get, route.id}, {:ok, route})
      end
      result
    end do
      {:ok, routes} -> routes
      {:error, _} -> []
    end
  end

  @doc """

  Returns a single route by ID

  """
  @spec get(String.t) :: Routes.Route.t | nil
  def get(id) do
    case cache id, fn id ->
      with %{data: [route]} <- V3Api.Routes.get(id) do
        {:ok, parse_route(route)}
      end
    end do
      {:ok, route} -> route
      {:error, _} -> nil
    end
  end

  @spec get_shapes(String.t, 0|1, boolean) :: [Routes.Shape.t]
  def get_shapes(route_id, direction_id, filter_negative_priority? \\ true) do
    shapes = cache {route_id, direction_id}, fn _ ->
      case V3Api.Shapes.all([route: route_id, direction_id: direction_id]) do
        {:error, _} -> []
        %JsonApi{data: data} ->
          shapes = Enum.flat_map(data, &parse_shape/1)
          for shape <- shapes do
            ConCache.put(__MODULE__, {:get_shape, shape.id}, [shape])
          end
          shapes
      end
    end
    filter_shapes_by_priority(shapes, filter_negative_priority?)
  end

  @spec filter_shapes_by_priority([Routes.Shape.t], boolean) :: [Routes.Shape.t]
  defp filter_shapes_by_priority(shapes, true) do
    for shape <- shapes,
      shape.priority >= 0 do
        shape
    end
  end
  defp filter_shapes_by_priority(shapes, false) do
    shapes
  end

  @spec get_shape(String.t) :: [Routes.Shape.t]
  def get_shape(shape_id) do
    cache shape_id, fn _ ->
      case V3Api.Shapes.by_id(shape_id) do
        {:error, _} -> []
        %JsonApi{data: data} ->
          Enum.flat_map(data, &parse_shape/1)
      end
    end
  end

  @doc """

  Given a route_type (or list of route types), returns the list of routes matching that type.

  """
  @spec by_type([0..4] | 0..4) :: [Routes.Route.t]
  def by_type(types) when is_list(types) do
    types = Enum.sort(types)
    case cache types, &by_type_uncached/1 do
      {:ok, routes} -> routes
      {:error, _} -> []
    end
  end
  def by_type(type) do
    by_type([type])
  end

  @spec by_type_uncached([0..4]) :: {:ok, [Routes.Route.t]} | {:error, any}
  defp by_type_uncached(types) do
    case all() do
      [] -> {:error, "no routes"}
      routes -> {:ok, Enum.filter(routes, fn route -> route.type in types end)}
    end
  end

  @doc """

  Given a stop ID, returns the list of routes which stop there.

  """
  @spec by_stop(String.t, Keyword.t) :: [Routes.Route.t]
  def by_stop(stop_id, opts \\ []) do
    case cache {stop_id, opts}, fn {stop_id, opts} ->
      stop_id |> V3Api.Routes.by_stop(opts) |> handle_response
    end do
      {:ok, routes} -> routes
      {:error, _} -> []
    end
  end

  @doc """

  Given a route_id, returns a map with the headsigns for trips in the given
  directions (by direction_id).

  """
  @spec headsigns(String.t) :: %{0 => [String.t], 1 => [String.t]}
  def headsigns(id) do
    cache id, fn id ->
      [zero_task, one_task] = for direction_id <- [0, 1] do
        Task.async(__MODULE__, :fetch_headsigns, [id, direction_id])
      end
      %{
        0 => Task.await(zero_task),
        1 => Task.await(one_task)
      }
    end
  end

  @spec fetch_headsigns(Routes.Route.id_t, non_neg_integer) :: [String.t]
  def fetch_headsigns(route_id, direction_id) do
    route_id
    |> V3Api.Trips.by_route("fields[trip]": "headsign", direction_id: direction_id)
    |> calculate_headsigns(route_id)
  end

  @spec calculate_headsigns(JsonApi.t | JsonApi.Error.t, Routes.Route.id_t) :: [Routes.Route.id_t]
  def calculate_headsigns(%JsonApi{data: data}, route_id) do
    data
    |> filter_non_primary_routes(route_id)
    |> Enum.flat_map(&get_headsign(&1))
    |> order_by_frequency
  end
  def calculate_headsigns(_) do
    []
  end

  defp get_headsign(%{attributes: %{"headsign" => ""}}), do: []
  defp get_headsign(%{attributes: %{"headsign" => headsign}}), do: [headsign]

  @spec filter_non_primary_routes([JsonApi.Item.t], Routes.Route.id_t) :: [JsonApi.t | JsonApi.Error.t]
  defp filter_non_primary_routes(trips, route_id), do: Enum.filter(trips, &route_id_matches?(&1, route_id))

  @spec route_id_matches?(JsonApi.Item.t, Routes.Route.id_t) :: boolean
  defp route_id_matches?(trip, route_id), do: Enum.any?(trip.relationships["route"], fn(trip) -> trip.id == route_id end)

  @spec handle_response(JsonApi.t | {:error, any}) :: {:ok, [Routes.Route.t]} | {:error, any}
  def handle_response({:error, reason}) do
    {:error, reason}
  end
  def handle_response(%{data: data}) do
    {:ok, data
    |> Enum.reject(&route_hidden?/1)
    |> Enum.map(&parse_route/1)
    }
  end

  @doc """
  Determines if the given route-data is hidden
  """
  @spec route_hidden?(%{id: String.t}) :: boolean
  def route_hidden?(%{id: "746"}), do: true
  def route_hidden?(%{id: "2427"}), do: true
  def route_hidden?(%{id: "3233"}), do: true
  def route_hidden?(%{id: "3738"}), do: true
  def route_hidden?(%{id: "4050"}), do: true
  def route_hidden?(%{id: "627"}), do: true
  def route_hidden?(%{id: "725"}), do: true
  def route_hidden?(%{id: "8993"}), do: true
  def route_hidden?(%{id: "116117"}), do: true
  def route_hidden?(%{id: "214216"}), do: true
  def route_hidden?(%{id: "441442"}), do: true
  def route_hidden?(%{id: "9701"}), do: true
  def route_hidden?(%{id: "9702"}), do: true
  def route_hidden?(%{id: "9703"}), do: true
  def route_hidden?(%{id: "Logan-" <> _}), do: true
  def route_hidden?(%{id: "CapeFlyer"}), do: true
  def route_hidden?(%{id: "Boat-F3"}), do: true
  def route_hidden?(_), do: false

  defp order_by_frequency(enum) do
    # the complicated function in the middle collapses some lengths which are
    # close together and allows us to instead sort by the name.  For example,
    # on the Red line, Braintree has 649 trips, Ashmont has 647.  The
    # division by -4 with a round makes them both -162 and so equal.  We
    # divide by -4 so that the ordering by count is large to small, but the
    # name ordering is small to large.
    enum
    |> Enum.group_by(&(&1))
    |> Enum.sort_by(fn {value, values} -> {
      values
      |> length
      |> (fn v -> Float.round(v / -4) end).(), value}
    end)
    |> Enum.map(&(elem(&1, 0)))
  end
end
