defmodule GreenLine do
  @moduledoc """
  Functions for handling the Green Line and its associated schedules.
  """

  alias Routes.Route
  alias Stops.Stop

  @type stop_routes_pair :: {[Stop.t], MapSet.t}

  @doc """
  Returns the list of Green Line stops, as well as a MapSet of {stop_id, route_id} pairs to signify
  that a stop is on the branch in question.
  """
  @spec stops_on_routes() :: stop_routes_pair
  def stops_on_routes() do
    ~w(Green-B Green-C Green-D Green-E)s
    |> Task.async_stream(&green_line_stops/1)
    |> Enum.reduce({[], MapSet.new}, &merge_green_line_stops/2)
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

  # Returns the stops that are on a given branch of the Green line,
  # along with the route ID.
  @spec green_line_stops(Route.id_t) :: {Route.id_t, [Stop.t]}
  defp green_line_stops(route_id) do
    stops = route_id
    |> Stops.Repo.by_route(0)
    |> Enum.drop_while(& not terminus?(&1.id, route_id))

    {route_id, stops}
  end

  # Returns the current full list of stops on the Green line, along with a
  # MapSet for all {stop_id, route_id} pairs where that stop in on that route.
  # The {:ok, _} part of the pattern match is due to using Task.async_stream.
  @spec merge_green_line_stops({:ok, {Route.id_t, [Stop.t]}}, stop_routes_pair) :: stop_routes_pair
  defp merge_green_line_stops({:ok, {route_id, line_stops}}, {current_stops, stop_route_id_set}) do
    # update stop_route_id_set to tag the routes the stop is on
    stop_route_id_set = line_stops
    |> Enum.reduce(stop_route_id_set, fn %{id: stop_id}, set ->
      MapSet.put(set, {stop_id, route_id})
    end)

    current_stops = line_stops
    |> List.myers_difference(current_stops)
    |> Enum.flat_map(fn {_op, stops} -> stops end)

    {current_stops, stop_route_id_set}
  end
end
