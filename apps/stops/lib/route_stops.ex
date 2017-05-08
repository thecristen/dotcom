defmodule Stops.RouteStops do
  defstruct [:branch, :stops]

  @type t :: %__MODULE__{
    branch: String.t,
    stops: [Stops.RouteStop.t]
  }
  @type direction_id_t :: 0 | 1

  @branched_routes ["Red", "CR-Kingston", "CR-Providence", "CR-Newburyport"]

  alias Stops.RouteStop

  def branched_routes(), do: @branched_routes

  @doc """
  Builds a list of all stops (as %RouteStop{}) on a route in a single direction.
  """
  @spec by_direction([Stops.Stop.t], [Routes.Shape.t], Routes.Route.t, direction_id_t) :: t
  def by_direction(stops, shapes, %Routes.Route{} = route, direction_id) when is_integer(direction_id) do
    shapes
    |> get_shapes(route, direction_id)
    |> get_route_stops(stops, route, direction_id)
    |> Enum.chunk_by(& &1.branch)
    |> Enum.map(fn [%RouteStop{branch: branch}|_] = stops -> %__MODULE__{branch: branch, stops: stops} end)
  end

  @doc """
  For a route in a single direction, retrieves either the primary shape for that route, or the shapes
  of all of its branches.
  """
  @spec get_shapes([Routes.Shape.t], Routes.Route.t, direction_id_t) :: [Routes.Shape.t]
  def get_shapes([], _route, _direction_id), do: []
  def get_shapes(shapes, %Routes.Route{id: "Green-E"}, _) do
    # E line only has one shape -- once the bug mentioned below gets fixed we can remove this specific check
    [Enum.find(shapes, & &1.primary?)]
  end
  def get_shapes(shapes, %Routes.Route{id: "Green-" <> _}, _) do
    # there is a funny quirk with the green line at the moment where for all but the E line, the route marked
    # primary: false is actually the one we want to use. this is probably going to get fixed soon, at which point
    # we'll need to update this.
    case shapes do
      [shape] -> [shape]
      [_|_] -> [Enum.find(shapes, & &1.primary? == false)]
    end
  end
  def get_shapes(shapes, %Routes.Route{id: "CR-Kingston"}, 0) do
    # There are a number of issues with values that the shapes API returns for Kingston.
    # - It's returning multiple shapes with the same id and stop_ids but slightly different polylines;
    # - The primary shape incorrectly has Quincy Center twice, and doesn't include Plymouth;
    # - The only shapes that include Plymouth either skip Quincy and JFK, or they also include
    #       Kingston (both of these are technically correct -- some trips on this route actually do go
    #       to Kingston, and then literally reverse direction for a bit and go down the other branch to Kingston.)
    # Because of all this, it's just easier to process Kingston separately.

    shapes
    |> Enum.uniq_by(& &1.id)
    |> Enum.filter(& &1.primary? || &1.id == "9790004")
    |> Enum.map(fn shape ->
      if shape.name == "Plymouth" do
        %{shape | stop_ids: List.delete_at(shape.stop_ids, -2)}
      else
        %{shape | stop_ids: List.delete_at(shape.stop_ids, 1)}
      end
    end)
  end
  def get_shapes(shapes, %Routes.Route{id: route_id}, 0) when route_id in @branched_routes do
    shapes
  end
  def get_shapes(shapes, %Routes.Route{id: route_id}, 1) when route_id in @branched_routes do
    # Since a shape is named for its terminus, branched route shapes all have the same name when direction_id is 1.
    # So, we have to fetch the shapes for the other direction to get the branch names.
    route_id
    |> Routes.Repo.get_shapes(0)
    |> Enum.map(& &1.name)
    |> Enum.zip(shapes)
    |> Enum.map(fn {name, shape} -> %{shape | name: name} end)
  end
  def get_shapes(shapes, _route, _direction_id), do: Enum.filter(shapes, & &1.primary?)

  @doc """
  Given a route and a list of that route's shapes, generates a list of RouteStops representing all stops on that route. If the route has branches,
  the branched stops appear grouped together in order as part of the list.
  """
  @spec get_route_stops([Routes.Shape.t] | Routes.Shape.t, [Stops.Stop.t], Routes.Route.t, direction_id_t) :: [RouteStop.t]
  def get_route_stops([], [%Stops.Stop{}|_] = stops, route, direction_id) do
    # if the repo doesn't have any shapes, just fake one since we only need the name and stop_ids.

    stops
    |> List.last()
    |> Map.get(:id)
    |> do_get_route_stops(Enum.map(stops, & &1.id), stops, route, direction_id)
  end
  def get_route_stops([%Routes.Shape{} = shape], [%Stops.Stop{}|_] = stops, route, direction_id) do
    # If there is only one route shape, we know that we won't need to deal with merging branches so
    # we just return whatever the list of stops is without calling &merge_branches/3.
    do_get_route_stops(shape.name, shape.stop_ids, stops, route, direction_id)
  end
  def get_route_stops(shapes, stops, route, direction_id) do
    shapes
    |> Enum.map(& {&1.name, do_get_route_stops(&1.name, &1.stop_ids, stops, route, direction_id)})
    |> merge_branches(route, direction_id)
  end

  @spec do_get_route_stops(String.t, [Stops.Stop.id_t], [Stops.Stop.t], Routes.Route.t, direction_id_t) :: [RouteStop.t]
  defp do_get_route_stops(shape_name, stop_ids, [%Stops.Stop{}|_] = stops, route, direction_id) do
    stops = Enum.map(stops, &{&1.id, &1}) |> Enum.into(%{})
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
