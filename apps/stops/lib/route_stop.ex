defmodule Stops.RouteStop do
  @moduledoc """
  A helper module for generating some contextual information about stops on a route. RouteStops contain
  the following information:
  ```
    # RouteStop info for South Station on the Red Line (direction_id: 0)
    %Stops.RouteStop{
      id: "place-sstat",                                  # The id that the stop is typically identified by (i.e. the parent stop's id)
      name: "South Station"                               # Stop's display name
      zone: "1A"                                          # Commuter rail zone (will be nil if stop doesn't have CR routes)
      route: %Routes.Route{id: "Red"...}                  # The full Routes.Route for the parent route
      branch: nil                                         # Name of the branch that this stop is on for this route. will be nil unless the stop is actually on a branch.
      station_info: %Stops.Stop{id: "place-sstat"...}     # Full Stops.Stop struct for the parent stop.

      stop_features: [:commuter_rail, :bus, :accessible]  # List of atoms representing the icons that should be displayed for this stop.
      is_terminus?: false                                 # Whether this is either the first or last stop on the route.
    }
  ```

  """

  @type branch_name_t :: String.t | nil
  @type direction_id_t :: 0 | 1

  @type t :: %__MODULE__{
    id: Stops.Stop.id_t,
    name: String.t,
    zone: String.t,
    branch: branch_name_t,
    station_info: Stops.Stop.t,
    stop_features: [Stops.Repo.stop_feature],
    is_terminus?: boolean,
    is_beginning?: boolean
  }

  defstruct [
    :id,
    :name,
    :zone,
    :branch,
    :station_info,
    stop_features: [],
    is_terminus?: false,
    is_beginning?: false
  ]

  alias __MODULE__, as: RouteStop

  @doc """
  Given a route and a list of that route's shapes, generates a list of RouteStops representing all stops on that route. If the route has branches,
  the branched stops appear grouped together in order as part of the list.
  """
  @spec list_from_shapes([Routes.Shape.t], [Stops.Stop.t], Routes.Route.t, direction_id_t) :: [RouteStop.t]
  def list_from_shapes([], [], _route, _direction_id), do: [] # Can't build route stops if there are no stops or shapes
  def list_from_shapes([], [%Stops.Stop{}|_] = stops, route, _direction_id) do
    # if the repo doesn't have any shapes, just fake one since we only need the name and stop_ids.

    stops
    |> List.last()
    |> Map.get(:id)
    |> do_list_from_shapes(Enum.map(stops, & &1.id), stops, route)
  end
  def list_from_shapes([%Routes.Shape{} = shape], [%Stops.Stop{}|_] = stops, route, _direction_id) do
    # If there is only one route shape, we know that we won't need to deal with merging branches so
    # we just return whatever the list of stops is without calling &merge_branch_list/2.
    do_list_from_shapes(shape.name, shape.stop_ids, stops, route)
  end
  def list_from_shapes([%Routes.Shape{} = shape | _], stops, %Routes.Route{type: 4} = route, _direction_id) do
    # for the ferry, for now, just return a single branch
    do_list_from_shapes(shape.name, Enum.map(stops, & &1.id), stops, route)
  end
  def list_from_shapes(shapes, stops, route, direction_id) do
    shapes
    |> Enum.map(&do_list_from_shapes(&1.name, &1.stop_ids, stops, route))
    |> merge_branch_list(direction_id)
  end

  @spec do_list_from_shapes(String.t, [Stops.Stop.id_t], [Stops.Stop.t], Routes.Route.t) :: [RouteStop.t]
  defp do_list_from_shapes(shape_name, stop_ids, [%Stops.Stop{}|_] = stops, route) do
    stops = Map.new(stops, &{&1.id, &1})
    stop_ids
    |> Enum.map(& Map.get(stops, &1))
    |> Enum.filter(& &1)
    |> Util.EnumHelpers.with_first_last()
    |> Enum.with_index
    |> Task.async_stream(&build_route_stop(&1, shape_name, route))
    |> Enum.map(fn {:ok, stop} -> stop end)
  end

  @doc """
  Builds a RouteStop from information about a stop.
  """
  @spec build_route_stop({{Stops.Stop.t, boolean}, non_neg_integer}, String.t | nil, Routes.Route.t) :: RouteStop.t
  def build_route_stop({{%Stops.Stop{} = stop, is_terminus?}, idx}, shape_name, route) do
    %RouteStop{
      id: stop.id,
      name: stop.name,
      station_info: stop,
      branch: shape_name,
      is_terminus?: is_terminus?,
      is_beginning?: idx == 0,
      zone: Zones.Repo.get(stop.id),
      stop_features: Stops.Repo.stop_features(stop, exclude: [Routes.Route.icon_atom(route)])
    }
  end

  @spec merge_branch_list([[RouteStop.t]], direction_id_t) :: [RouteStop.t]
  defp merge_branch_list(branches, direction_id) do
    # If we know a route has branches, then we need to figure out which stops are on a branch vs. which stops
    # are shared. At this point, we have two lists of branches, and at the back end the stops are all the same,
    # but starting at some point in the middle the stops branch.
    branches
    |> Enum.map(&flip_branches_to_front(&1, direction_id))
    |> flatten_branches
    |> flip_branches_to_front(direction_id) # unflips the branches
  end

  @spec flatten_branches([[RouteStop.t]]) :: [RouteStop.t]
  defp flatten_branches(branches) do
    # We build a list of the shared stops between the branches, then unassign
    # the branch for each stop that's in the list of shared stops.
    shared_stop_ids = branches
    |> Enum.map(fn stops ->
      MapSet.new(stops, & &1.id)
    end)
    |> Enum.reduce(&MapSet.intersection/2)

    branches
    |> Enum.map(&unassign_branch_if_shared(&1, shared_stop_ids))
    |> Enum.reduce(&merge_two_branches/2)
  end

  @spec unassign_branch_if_shared([RouteStop.t], MapSet.t) :: [RouteStop.t]
  defp unassign_branch_if_shared(stops, shared_stop_ids) do
    for stop <- stops do
      if MapSet.member?(shared_stop_ids, stop.id) do
        %{stop | branch: nil}
      else
        stop
      end
    end
  end

  @spec merge_two_branches([RouteStop.t], [RouteStop.t]) :: [RouteStop.t]
  defp merge_two_branches(first, second) do
    {first_branch, first_core} = Enum.split_while(first, & &1.branch)
    {second_branch, second_core} = Enum.split_while(second, & &1.branch)

    core = [first_core, second_core]
    |> Enum.max_by(&length/1)
    |> Enum.map(& %{&1 | branch: nil})

    second_branch ++ first_branch ++ core
  end

  @spec flip_branches_to_front([RouteStop.t], direction_id_t) :: [RouteStop.t]
  defp flip_branches_to_front(branch, 0), do: Enum.reverse(branch)
  defp flip_branches_to_front(branch, 1), do: branch

  defimpl Stops.Position do
    def latitude(route_stop), do: route_stop.station_info.latitude
    def longitude(route_stop), do: route_stop.station_info.longitude
  end
end
