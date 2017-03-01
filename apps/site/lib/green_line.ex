defmodule GreenLine do
  @moduledoc """
  Functions for handling the Green Line and its associated schedules.
  """

  alias Routes.Route
  alias Stops.Stop

  @type route_id_stop_id_map :: %{Route.id_t => MapSet.t}
  @type stop_routes_pair :: {[Stop.t], route_id_stop_id_map}

  @doc """
  Returns the list of Green Line stops, as well as a MapSet of {stop_id, route_id} pairs to signify
  that a stop is on the branch in question.
  """
  @spec stops_on_routes(0 | 1) :: stop_routes_pair
  def stops_on_routes(direction_id) do
    branch_ids()
    |> Task.async_stream(&green_line_stops(&1, direction_id))
    |> Enum.reduce({[], %{}}, &merge_green_line_stops/2)
  end

  @doc """
  Returns whether or not the given stop is a terminus for the line. Assumes the given stop is
  actually on the line.
  """
  @spec terminus?(Stop.id_t, Route.id_t) :: boolean
  def terminus?(stop_id, "Green-B") when stop_id in ["place-lake", "place-pktrm"], do: true
  def terminus?(stop_id, "Green-C") when stop_id in ["place-north", "place-clmnl"], do: true
  def terminus?(stop_id, "Green-D") when stop_id in ["place-river", "place-gover"], do: true
  def terminus?(stop_id, "Green-E") when stop_id in ["place-lech", "place-hsmnl"], do: true
  def terminus?(_, _), do: false

  @doc """
  Given a stop ID, route ID, and route => stop set map, returns whether the stop is on the route.
  """
  @spec stop_on_route?(Stop.id_t, Route.id_t, stop_routes_pair) :: boolean
  def stop_on_route?(stop_id, route_id, {_, map}) do
    MapSet.member?(map[route_id], stop_id)
  end

  @doc """
  Returns all the stops on Green Line.
  """
  @spec all_stops(stop_routes_pair) :: [Stop.t]
  def all_stops({stops, _}) do
    stops
  end

  @doc """
  Returns stops on the specific branch of the line.
  """
  @spec route_stops(Route.id_t, stop_routes_pair) :: MapSet.t
  def route_stops(route_id, {_, map}) do
    map[route_id]
  end

  @doc """
  All the branch IDs of the Green Line.
  """
  @spec branch_ids() :: [Route.id_t]
  def branch_ids() do
    ~w(Green-B Green-C Green-D Green-E)s
  end

  @doc """
  The Green Line.
  """
  @spec green_line() :: Route.t
  def green_line() do
    %Routes.Route{
      id: "Green",
      name: "Green Line",
      direction_names: %{0 => "Westbound", 1 => "Eastbound"},
      type: 0
    }
  end

  @doc """
  Creates a map %{stop_id => [route_id]}
  where each stop_id key has a value of the Green line routes
  that stops at that Stop
  """
  @spec routes_for_stops(stop_routes_pair) :: %{Stop.id_t => [Route.id_t]}
  def routes_for_stops({_, route_sets}) do
    Enum.reduce(route_sets, Map.new(), &do_routes_for_stops/2)
  end

  @spec do_routes_for_stops({Route.id_t, MapSet.t}, %{Stop.id_t => [Route.id_t]}) :: %{Stop.id_t => [Route.id_t]}
  defp do_routes_for_stops({route_id, stop_set}, map) do
    Enum.reduce(stop_set, map, fn(stop_id, acc_map) -> Map.update(acc_map, stop_id, [route_id], & [route_id | &1]) end)
  end

  # Returns the stops that are on a given branch of the Green line,
  # along with the route ID.
  @spec green_line_stops(Route.id_t, 0 | 1) :: {Route.id_t, [Stop.t]}
  defp green_line_stops(route_id, direction_id) do
    stops = route_id
    |> Stops.Repo.by_route(direction_id)
    |> filter_lines(route_id)

    {route_id, stops}
  end

  @spec filter_lines([Stop.t], Route.id_t) :: [Stop.t]
  defp filter_lines(stops, route_id) do
    stops
    |> do_filter_lines(route_id, false, [])
    |> Enum.reverse
  end

  # Basically a state machine -- when one terminal is encountered it
  # begins adding stops to the accumulator; it then proceeds down the
  # list of stops until the other terminal is seen, at which point it
  # adds it on and returns the full list.
  @spec do_filter_lines([Stop.t], Route.id_t, boolean, [Stop.t]) :: [Stop.t]
  defp do_filter_lines(stops, route_id, in_line?, acc)
  defp do_filter_lines([], _route_id, _in_line?, acc) do
    acc
  end
  defp do_filter_lines([stop | stops], route_id, false, []) do
    if terminus?(stop.id, route_id) do
      do_filter_lines(stops, route_id, true, [stop])
    else
      do_filter_lines(stops, route_id, false, [])
    end
  end
  defp do_filter_lines([stop | stops], route_id, true, acc) do
    if terminus?(stop.id, route_id) do
      [stop | acc]
    else
      do_filter_lines(stops, route_id, true, [stop | acc])
    end
  end

  # Returns the current full list of stops on the Green line, along with a
  # map of {route_id => [stop_id]} representing all the stops on the route.
  # The {:ok, _} part of the pattern match is due to using Task.async_stream.
  @spec merge_green_line_stops({:ok, {Route.id_t, [Stop.t]}}, stop_routes_pair) :: stop_routes_pair
  defp merge_green_line_stops({:ok, {route_id, line_stops}}, {current_stops, route_id_stop_map}) do
    # Update route_id_stop_map to include the stop
    route_id_stop_map = line_stops
    |> Enum.reduce(route_id_stop_map, fn %{id: stop_id}, map ->
      Map.put(map, route_id, MapSet.put(Map.get(map, route_id, MapSet.new), stop_id))
    end)

    current_stops = line_stops
    |> List.myers_difference(current_stops)
    |> Enum.flat_map(fn {_op, stops} -> stops end)

    {current_stops, route_id_stop_map}
  end
end
