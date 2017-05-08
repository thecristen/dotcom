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
      stop_number: 9                                      # The number (0-based) of the stop along the route, relative to the beginning of the line in this direction.
                                                          #     note that for routes with branches, stops that are on branches will be ordered as if no other branches
                                                          #     exist. So, for example, on the Red line (direction_id: 0), the stop number for JFK/Umass is 12, and then
                                                          #     the stop number for both Savin Hill (ashmont) and North Quincy (braintree) is 13, the next stop on both
                                                          #     branches is 14, etc.
      station_info: %Stops.Stop{id: "place-sstat"...}     # Full Stops.Stop struct for the parent stop.
      child_stops: ["70079", "70080"]                     # List of the ids of all the child GTFS stops that this stop represents for this route & direction.

      stop_features: [:commuter_rail, :bus, :accessible]  # List of atoms representing the icons that should be displayed for this stop.
      is_terminus?: false                                 # Whether this is either the first or last stop on the route. Use in conjunction with stop_number to determine
                                                          #     if this is the first or last stop.
    }
  ```

  """

  @type branch_name_t :: String.t
  @type direction_id_t :: 0 | 1
  @type stop_number_t :: integer

  @branched_routes ["Red", "CR-Kingston", "CR-Providence", "CR-Newburyport"]

  @type t :: %__MODULE__{
    id: Stops.Stop.id_t,
    name: String.t,
    zone: String.t,
    route: Routes.Route.t,
    branch: branch_name_t,
    stop_number: non_neg_integer,
    station_info: Stops.Stop.t,
    child_stops: [Stops.Stop.id_t],
    stop_features: [Routes.Route.route_type | Routes.Route.subway_lines_type | :accessible],
    is_terminus?: boolean
  }

  defstruct [
    :id,
    :name,
    :zone,
    :route,
    :branch,
    :stop_number,
    :station_info,
    child_stops: [],
    stop_features: [],
    is_terminus?: false
  ]

  alias __MODULE__, as: RouteStop

  def branched_routes, do: @branched_routes

  @doc """
  Given a route and a list of that route's shapes, generates a list of RouteStops representing all stops on that route. If the route has branches,
  the branched stops appear grouped together in order as part of the list.
  """
  @spec list_from_shapes([Routes.Shape.t], [Stops.Stop.t], Routes.Route.t, direction_id_t) :: [RouteStop.t]
  def list_from_shapes([], [%Stops.Stop{}|_] = stops, route, direction_id) do
    # if the repo doesn't have any shapes, just fake one since we only need the name and stop_ids.

    stops
    |> List.last()
    |> Map.get(:id)
    |> do_list_from_shapes(Enum.map(stops, & &1.id), stops, route, direction_id)
  end
  def list_from_shapes([%Routes.Shape{} = shape], [%Stops.Stop{}|_] = stops, route, direction_id) do
    # If there is only one route shape, we know that we won't need to deal with merging branches so
    # we just return whatever the list of stops is without calling &merge_branches/3.
    do_list_from_shapes(shape.name, shape.stop_ids, stops, route, direction_id)
  end
  def list_from_shapes(shapes, stops, route, direction_id) do
    shapes
    |> Enum.map(& {&1.name, do_list_from_shapes(&1.name, &1.stop_ids, stops, route, direction_id)})
    |> merge_branches(route, direction_id)
  end

  @spec do_list_from_shapes(String.t, [Stops.Stop.id_t], [Stops.Stop.t], Routes.Route.t, direction_id_t) :: [RouteStop.t]
  defp do_list_from_shapes(shape_name, stop_ids, [%Stops.Stop{}|_] = stops, route, direction_id) do
    stops = Map.new(stops, &{&1.id, &1})
    stop_ids
    |> Enum.map(& Map.get(stops, &1))
    |> Util.EnumHelpers.with_first_last()
    |> Enum.with_index()
    |> Task.async_stream(fn stop -> build_route_stop(stop, shape_name, route, direction_id) end)
    |> Enum.map(fn {:ok, stop} -> stop end)
  end

  @doc """
  Builds a RouteStop from information about a stop.
  """
  @spec build_route_stop({{Stops.Stop.t, boolean}, RouteStop.stop_number_t}, Routes.Shape.t, Routes.Route.t, direction_id_t) :: RouteStop.t
  def build_route_stop({{%Stops.Stop{} = stop, is_terminus?}, index}, shape_name, route, direction_id) do
    %RouteStop{
      id: stop.id,
      route: route,
      name: stop.name,
      station_info: stop,
      branch: shape_name,
      is_terminus?: is_terminus?,
      zone: Zones.Repo.get(stop.id),
      stop_number: %{direction_id => index},
      stop_features: get_stop_features(stop.id, route, stop.accessibility)
    }
  end

  @doc """
  Builds the stop_features list for a RouteStop.
  """
  @spec get_stop_features(Stops.Stop.id_t, Routes.Route.t, [atom]) :: [atom]
  def get_stop_features(stop_id, %Routes.Route{} = route, accessibility_features) do
    route_feature = Routes.Route.icon_atom(route)
    stop_id
    |> Routes.Repo.by_stop
    |> Enum.map(&Routes.Route.icon_atom/1)
    |> Enum.reject(& &1 == route_feature)
    |> Enum.uniq()
    |> add_accessibility(accessibility_features)
    |> Enum.sort_by(&sort_feature_icons/1)
  end

  @spec add_accessibility([atom], [String.t]) :: [atom]
  defp add_accessibility(stop_features, ["accessible" | _]), do: [:access | stop_features]
  defp add_accessibility(stop_features, _), do: stop_features

  @spec sort_feature_icons(atom) :: integer
  defp sort_feature_icons(:commuter_rail), do: 0
  defp sort_feature_icons(:bus), do: 2
  defp sort_feature_icons(:access), do: 10
  defp sort_feature_icons(_), do: 1

  @spec merge_branches([{RouteStop.branch_name_t, [RouteStop.t]}], Routes.Route.t, direction_id_t) :: [RouteStop.t]
  defp merge_branches([{_shape, route_stops}], %Routes.Route{id: "Green-"<>_}, direction_id) do
    # Green line branches are merged separately
    {direction_id, route_stops}
  end
  defp merge_branches(branches, %Routes.Route{id: route_id}, direction_id) when route_id in @branched_routes do
    # If we know a route has branches, then we need to figure out which stops are on a branch vs. which stops
    # are shared. At this point, we have two lists of branches, and at one end the stops are all the same,
    # but starting at some point in the middle the stops branch. So, we zip the lists of stops together and
    # look at each tuple one by one to determine where the branches start. For each row, if the stop id is
    # the same, then we know that the branches have not diverged yet. Once we've found the branch point, we update
    # the branch information for each stop, then unzip the branched stops and concatenate them separately onto
    # the end of the unbranched stops.
    branches
    |> Enum.map(&reverse?(&1, direction_id))
    |> pad_shorter_branch_and_zip()
    |> Enum.split_while(&stop_on_all_branches?/1)
    |> do_merge_branches()
    |> reverse?(direction_id)
  end

  @spec pad_shorter_branch_and_zip([{RouteStop.branch_name_t, [RouteStop.t]}]) :: [{RouteStop.t, RouteStop.t}]
  defp pad_shorter_branch_and_zip([{_branch_name, _branch_stops}|_] = branches) do
    # in order to zip the branches together without losing any stops, we pad the shorter branch with
    # some placeholder nils to make them temporarily the same length.
    longest = branches
    |> Enum.map(& elem(&1, 1))
    |> Enum.max_by(&length/1)
    |> length()

    Enum.map(branches, fn {_branch_name, list} ->
      padding = longest - length(list)
      if padding > 0 do
        1..padding
        |> Enum.map(fn _ -> %RouteStop{} end)
        |> Kernel.++(Enum.reverse(list))
        |> Enum.reverse()
      else
        list
      end
    end)
    |> Enum.zip()
  end

  @spec reverse?({RouteStop.branch_name_t, [RouteStop.t]} | [RouteStop.t], direction_id_t) :: {RouteStop.branch_name_t, [RouteStop.t]} | [RouteStop.t]
  defp reverse?({branch_name, branch_stops}, 1) do
    # all branches are at the end of the line when direction_id is 0, so if direction_id is 1, we reverse the list
    # temporarily to ensure that it's processed in the correct order.
    {branch_name, Enum.reverse(branch_stops)}
  end
  defp reverse?(stop_list, 1) when is_list(stop_list), do: Enum.reverse(stop_list)
  defp reverse?(stop_list, _), do: stop_list

  @spec stop_on_all_branches?(tuple) :: boolean
  defp stop_on_all_branches?(branches_stops) do
    branches_stops
    |> Tuple.to_list()
    |> Enum.uniq_by(& &1.id)
    |> length()
    |> Kernel.==(1)
  end

  @spec do_merge_branches({[RouteStop.t], [RouteStop.t]}) :: [RouteStop.t]
  defp do_merge_branches({unbranched_stops, branched_stops}) do
    [
      Enum.map(unbranched_stops, & &1 |> elem(0) |> Map.put(:branch, nil)),
      unzip_branches(branched_stops)
    ]
    |> List.flatten()
  end

  @spec unzip_branches([tuple]) :: [RouteStop.t]
  def unzip_branches([{_branch_1_stop_1, _branch_2_stop_2}|_other_branch] = branched_stops) do
    branched_stops
    |> Enum.unzip()
    |> Tuple.to_list()
    |> Enum.reduce([], &merge_branch_stops/2)
  end

  def merge_branch_stops(branch, acc) do
    branch
    |> Enum.reject(fn %RouteStop{id: id} -> id == nil end)
    |> Enum.concat(acc)
  end
end
