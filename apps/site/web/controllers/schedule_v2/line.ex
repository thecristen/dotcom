defmodule Site.ScheduleV2Controller.Line do

  import Plug.Conn, only: [assign: 3]
  import Site.Router.Helpers
  alias Stops.{RouteStops, RouteStop}
  alias Routes.{Route, Shape}

  @type stop_bubble_type :: :stop | :terminus | :line | :empty | :merge
  @type query_param :: String.t | nil
  @type branch_name :: String.t | nil
  @type direction_id :: 0 | 1
  @type stop_bubble :: {branch_name, stop_bubble_type}
  @type stop_with_bubble_info :: {[stop_bubble], RouteStop.t}

  def init([]), do: []

  def call(%Plug.Conn{assigns: %{route: %Route{} = route}} = conn, _args) do
    direction_id = case conn do
      %{query_params: %{"direction_id" => id}} -> String.to_integer(id)
      _ -> 0
    end
    expanded = conn.query_params["expanded"]
    variant = conn.query_params["variant"]
    update_conn(conn, route, direction_id, expanded, variant)
  end

  @spec update_conn(Plug.Conn.t, Route.t, direction_id, query_param, query_param) :: Plug.Conn.t
  defp update_conn(conn, route, direction_id, expanded, variant) do
    all_shapes = get_all_shapes(route.id, direction_id)
    active_shapes = get_active_shapes(all_shapes, route, variant, expanded)
    branches = get_branches(all_shapes, active_shapes, route, direction_id)
    collapsed_branches = remove_collapsed_stops(branches, expanded, direction_id)
    map_data = get_map_data(branches, {all_shapes, active_shapes}, route.id, expanded)
    map_polylines = map_polylines(map_data, route)
    map_img_src = map_img_src(map_data, map_polylines, route)
    map_color = map_color(route.type, route.id)

    conn
    |> assign(:direction_id, direction_id)
    |> assign(:all_stops, build_stop_list(collapsed_branches, direction_id))
    |> assign(:expanded, conn.query_params["expanded"])
    |> assign(:branches, collapsed_branches)
    |> assign(:all_shapes, all_shapes)
    |> assign(:active_shape, active_shape(active_shapes, route.type))
    |> assign(:map_img_src, map_img_src)
    |> assign(:dynamic_map_data, dynamic_map_data(map_color, map_polylines, map_data, conn.assigns.vehicle_tooltips))
  end

  # I can't figure out why Dialyzer thinks this can only be called with
  # route_type == 4, Ferry. Since I've already spent more time than I should
  # have, I'm ignoring this small function and moving on for now. -ps
  @dialyzer [nowarn_function: [active_shape: 2]]
  @spec active_shape(shapes :: [Shape.t], route_type :: 0..4) :: Shape.t | nil
  defp active_shape([active | _], 3) do
    active
  end
  defp active_shape(_shapes, _route_type) do
    nil
  end

  @doc """
  Gathers all of the shapes for the route. Green Line has to make a call for each branch separately, because of course
  it does.
  """
  @spec get_all_shapes(Routes.Route.id_t, direction_id) :: [Routes.Shape.t]
  def get_all_shapes("Green", direction_id) do
    GreenLine.branch_ids()
    |> Enum.map(& Task.async(fn -> get_all_shapes(&1, direction_id) end))
    |> Enum.flat_map(&Task.await/1)
  end
  def get_all_shapes(route_id, direction_id) do
    Routes.Repo.get_shapes(route_id, direction_id)
  end

  @spec get_active_shapes([Routes.Shape.t], Routes.Route.t, query_param, branch_name) :: [Routes.Shape.t]
  defp get_active_shapes(shapes, %Routes.Route{type: 3}, variant, _expanded) do
    shapes
    |> get_requested_shape(variant)
    |> get_default_shape(shapes)
  end
  defp get_active_shapes(shapes, %Routes.Route{id: "Green"}, _variant, nil), do: shapes
  defp get_active_shapes(shapes, %Routes.Route{id: "Green"}, _variant, expanded) do
    index = if expanded == "Green-D", do: 1, else: 0
    headsign = expanded
    |> Routes.Repo.headsigns()
    |> Map.get(0)
    |> Enum.at(index)
    [Enum.find(shapes, & &1.name == headsign)]
  end
  defp get_active_shapes(shapes, _route, _variant, _expanded), do: shapes

  @spec get_requested_shape([Routes.Shape.t], query_param) :: Routes.Shape.t | nil
  defp get_requested_shape(_shapes, nil), do: nil
  defp get_requested_shape(shapes, variant), do: Enum.find(shapes, &(&1.id == variant))

  @spec get_default_shape(Routes.Shape.t | nil, [Routes.Shape.t]) :: [Routes.Shape.t]
  defp get_default_shape(nil, [default | _]), do: [default]
  defp get_default_shape(%Routes.Shape{} = shape, _shapes), do: [shape]

  @doc """
  Gets a list of RouteStops representing all of the branches on the route. Routes without branches will always be a
  list with a single RouteStops struct.
  """
  @spec get_branches([Routes.Shape.t], [Routes.Shape.t], Routes.Route.t, direction_id) :: [RouteStops.t]
  def get_branches(all_shapes, _, %Routes.Route{id: "Green"}, direction_id) do
    GreenLine.branch_ids()
    |> Enum.map(&get_green_branch(&1, all_shapes, direction_id))
    |> Enum.map(&Task.await/1)
    |> Enum.reverse()
  end
  def get_branches(_, [active_shape], %Routes.Route{type: 3} = route, direction_id) do
    # For bus routes, we only want to show the stops for the active route variant.
    do_get_branches([active_shape], route, direction_id)
  end
  def get_branches(all_shapes, _, route, direction_id), do: do_get_branches(all_shapes, route, direction_id)

  defp do_get_branches(shapes, route, direction_id) do
    route.id
    |> Stops.Repo.by_route(direction_id)
    |> RouteStops.by_direction(shapes, route, direction_id)
  end

  @spec get_green_branch(GreenLine.branch_name, [Routes.Shape.t], direction_id) :: Task.t  # returns Stops.RouteStops.t
  defp get_green_branch(branch_id, shapes, direction_id) do
    Task.async(fn ->
      headsign = branch_id
      |> Routes.Repo.headsigns()
      |> Map.get(direction_id)
      |> List.first()

      branch = shapes
      |> Enum.filter(& &1.name == headsign)
      |> get_branches([], %Routes.Route{id: branch_id, type: 0}, direction_id)
      |> List.first()

      %{branch | branch: branch_id, stops: Enum.map(branch.stops, &update_green_branch_stop(&1, branch_id))}
    end)
  end

  @spec update_green_branch_stop(RouteStop.t, GreenLine.branch_name) :: RouteStop.t
  defp update_green_branch_stop(stop, branch_id) do
    # Green line shapes use the headway as their name, so each RouteStop comes back from the repo with their
    # branch set to "Heath St." etc. We change the stop's branch name to nil if the stop is shared, or to the branch
    # id if it's not shared.
    GreenLine.shared_stops()
    |> Enum.member?(stop.id)
    |> do_update_green_branch_stop(stop, branch_id)
  end

  @spec do_update_green_branch_stop(boolean, RouteStop.t, branch_name) :: RouteStop.t
  defp do_update_green_branch_stop(true, stop, _branch_id), do: %{stop | branch: nil}
  defp do_update_green_branch_stop(false, stop, branch_id), do: %{stop | branch: branch_id}

  @doc """
  For each branch, determines whether that branch is expanded. If true, it returns all of the branch's stops.
  If false, it returns only the last stop on that branch. For collapsed branches on the Green Line, it returns
  all shared stops on that branch + the branch terminus.
  """
  @spec remove_collapsed_stops([RouteStops.t], String.t, 0 | 1) :: [RouteStops.t]
  def remove_collapsed_stops([all_stops], _, _), do: [all_stops]
  def remove_collapsed_stops(branches, expanded, direction_id) do
    Enum.map(branches, & do_remove_collapsed_stops(&1, expanded, direction_id))
  end

  @spec do_remove_collapsed_stops(RouteStops.t, branch_name, direction_id) :: RouteStops.t
  defp do_remove_collapsed_stops(%RouteStops{branch: nil} = branch, _, _) do
    # if the branch's name is nil, it represents the unbranched stops on the route, so no stops should be removed.
    branch
  end
  defp do_remove_collapsed_stops(%RouteStops{branch: branch_id} = branch, branch_id, _) do
    # no stops should be removed if the branch is expanded.
    branch
  end
  defp do_remove_collapsed_stops(%RouteStops{branch: "Green-" <> _} = branch, _expanded_branch, 0) do
    {shared, not_shared} = Enum.split_while(branch.stops, & &1.id != GreenLine.split_id(branch.branch))
    %{branch | stops: shared ++ [List.last(not_shared)]}
  end
  defp do_remove_collapsed_stops(%RouteStops{branch: "Green-" <> _} = branch, _expanded_branch, 1) do
    {not_shared, shared} = Enum.split_while(branch.stops, & &1.id != GreenLine.merge_id(branch.branch))
    %{branch | stops: [List.first(not_shared)] ++ shared}
  end
  defp do_remove_collapsed_stops(%RouteStops{} = branch, _expanded, direction_id) do
    stop = case direction_id do
      0 -> List.last(branch.stops)
      1 -> List.first(branch.stops)
    end
    %{branch | stops: [stop]}
  end

  @spec get_map_data([RouteStops.t], {[Shape.t], [Shape.t]}, Route.id_t, query_param) :: {[Stops.Stop.t], [Shape.t]}
  defp get_map_data(branches, {all_shapes, _active_shapes}, "Green", expanded_branch) when not is_nil(expanded_branch) do
    stops = branches |> Enum.filter(& &1.branch == expanded_branch) |> get_map_stops()
    {stops, all_shapes}
  end
  defp get_map_data(branches, {all_shapes, _active_shapes}, "Green", _expanded) do
    {get_map_stops(branches), all_shapes}
  end
  defp get_map_data(branches, {_all_shapes, active_shapes}, _route_id, _expanded) do
    {get_map_stops(branches), active_shapes}
  end

  @spec get_map_stops([RouteStops.t]) :: [Stops.Stop.t]
  defp get_map_stops(branches) do
    branches
    |> Enum.flat_map(& &1.stops)
    |> Enum.uniq_by(& &1.id)
    |> Enum.map(& &1.station_info)
  end

  @doc """

  Returns an image to display on the right/bottom part of the page.  For CR,
  and bus, we display a Google Map with the stops.  For others, we display a spider
  map.

  """
  @spec map_img_src({[Stops.Stop.t], any}, [String.t], Routes.Route.t) :: String.t
  def map_img_src(_, _, %Routes.Route{type: 4}) do
    static_url(Site.Endpoint, "/images/ferry-spider.jpg")
  end
  def map_img_src({stops, _shapes}, polylines, route) do
    polylines
    |> Enum.map(&{:path, "color:0x#{map_color(route.type, route.id)}FF|enc:#{&1}"})
    |> do_map_img_src(stops, route)
  end

  @spec map_polylines({any, [Routes.Shape.t]}, Routes.Route.t) :: [String.t]
  defp map_polylines(_, %Routes.Route{type: 4}), do: ""
  defp map_polylines({_stops, shapes}, _) do
    shapes
    |> Enum.flat_map(& PolylineHelpers.condense([&1.polyline]))
  end

  @spec do_map_img_src(Keyword.t, [Stops.Stop.t], Routes.Route.t) :: String.t
  defp do_map_img_src(paths, stops, route) do
    opts = paths ++ [
      markers: markers(stops, route.type, route.id)
    ]
    GoogleMaps.static_map_url(600, 600, opts)
  end

  @spec map_color(0..4, String.t) :: String.t
  defp map_color(3, _id), do: "FFCE0C"
  defp map_color(2, _id), do: "A00A78"
  defp map_color(_type, "Blue"), do: "0064C8"
  defp map_color(_type, "Red"), do: "FF1428"
  defp map_color(_type, "Mattapan"), do: "FF1428"
  defp map_color(_type, "Orange"), do: "FF8200"
  defp map_color(_type, "Green"), do: "428608"
  defp map_color(_type, _id), do: "0064C8"

  @spec markers([Stops.Stop.t], 0..4, String.t) :: String.t
  defp markers(stops, type, id) do
    ["anchor:center",
     "icon:#{map_stop_icon_path(type, id)}",
     marker_path(stops)]
    |> Enum.join("|")
  end

  @spec marker_path([Stops.Stop.t]) :: String.t
  defp marker_path(stops) do
    stops
    |> Enum.map(&position_string/1)
    |> Enum.join("|")
  end

  @spec position_string(%{latitude: float(), longitude: float()}) :: String.t
  defp position_string(%{latitude: latitude, longitude: longitude}) do
    "#{Float.floor(latitude, 4)},#{Float.floor(longitude, 4)}"
  end

  @spec map_stop_icon_path(0..4, String.t) :: String.t
  defp map_stop_icon_path(type, id) do
    static_url(Site.Endpoint, "/images/map-#{map_color(type, id)}-dot-icon.png")
  end

  @doc """

  Builds a list of all stops on a route; stops are represented by tuples of

    { [ {branch_name, bubble_type} ], %RouteStop{} }

  `[ {branch_name, bubble_type} ]` represents all of the stop bubbles to display on that stop's row.

  `branch_name` is used by the green line to display the branch's letter.

  """
  @spec build_stop_list([RouteStops.t], 0 | 1) :: [stop_with_bubble_info]
  def build_stop_list([%RouteStops{branch: "Green-" <> _}|_] = branches, direction_id) do
    branches
    |> Enum.reverse()
    |> Enum.reduce({[], []}, &reduce_green_branch(&1, &2, direction_id))
    |> build_green_stop_list(direction_id)
  end
  def build_stop_list([%RouteStops{stops: stops}], _direction_id) do
    stops
    |> Util.EnumHelpers.with_first_last()
    |> Enum.map(fn {stop, is_terminus?} ->
      bubble_type = if is_terminus?, do: :terminus, else: :stop
      {[{nil, bubble_type}], %{stop | branch: nil}}
    end)
  end
  def build_stop_list(branches, direction_id) do
    branches
    |> do_build_stop_list(direction_id)
    |> sort_stop_list(direction_id)
  end

  def do_build_stop_list(branches, direction_id) do
    branches
    |> sort_branches(direction_id)
    |> Enum.reduce({[], []}, &build_branched_stop_list/2)
  end

  # Reduces each green line branch into a tuple of {stops_on_branches, shared_stops}, which gets parsed
  # by &build_green_stop_list/2.
  @spec reduce_green_branch(RouteStops.t,
                           {[RouteStop.t], [RouteStop.t]}, 0 | 1) :: {[stop_with_bubble_info], [RouteStop.t]}
  defp reduce_green_branch(branch, acc, direction_id) do
    branch
    |> split_green_branch(direction_id)
    |> parse_green_branch(acc, direction_id, branch.branch)
  end

  # Pulls together the results of &reduce_green_branches/3 and compiles the full list of Green Line stops
  # in the expected order based on direction_id. Unshared stops have already had their bubble types generated in
  # &parse_green_branch/4; shared stops get their bubble types generated here, after the shared stops have
  # been reduced to a unique list.
  @spec build_green_stop_list({[stop_with_bubble_info], [RouteStop.t]}, direction_id) :: [stop_with_bubble_info]
  defp build_green_stop_list({branch_stops, shared_stops}, 1) do
    shared_stops
    |> Enum.uniq_by(& &1.id)
    |> Enum.reduce([], &build_branched_stop(&1, &2, {&1.branch, GreenLine.branch_ids()}))
    |> Kernel.++(branch_stops)
    |> Enum.reverse()
  end
  defp build_green_stop_list({branch_stops, shared_stops}, 0) do
    shared_stops
    |> Enum.uniq_by(& &1.id)
    |> Enum.reverse()
    |> Enum.reduce(Enum.reverse(branch_stops), &build_branched_stop(&1, &2, {&1.branch, GreenLine.branch_ids()}))
  end

  # Splits green branch into a tuple of shared stops and stops that are unique to that branch.
  @spec split_green_branch(RouteStops.t, 0 | 1) :: {[RouteStop.t], [RouteStop.t]}
  defp split_green_branch(%RouteStops{branch: "Green-E", stops: stops}, _direction_id), do: {[], stops}
  defp split_green_branch(%RouteStops{stops: stops, branch: branch_id}, 1) do
    Enum.split_while(stops, fn stop -> stop.id != GreenLine.merge_id(branch_id) end)
  end
  defp split_green_branch(%RouteStops{stops: stops, branch: branch_id}, 0) do
    {shared, [merge | branch]} = Enum.split_while(stops, fn stop -> stop.id != GreenLine.merge_id(branch_id) end)
    {branch, shared ++ [merge]}
  end

  # Adds stops on a green line branch to the tuple that represents all Green Line stops.
  # If a stop is not shared, its stop bubble info gets generated here.
  # Shared stops are simply added to the list of all shared stops -- their stop bubble info is generated later,
  # so that we don't duplicate efforts.
  @spec parse_green_branch({[RouteStop.t], [RouteStop.t]},
                           {[stop_with_bubble_info], [RouteStop.t]},
                           direction_id, branch_name) :: {[stop_with_bubble_info], [RouteStop.t]}
  defp parse_green_branch({branch_stops, shared_stops}, acc, direction_id, branch_name) do
    branch_stops
    |> Enum.reduce([], &build_branched_stop(&1, &2, {branch_name, GreenLine.branch_ids()}))
    |> do_parse_green_branch(shared_stops, acc, direction_id)
  end

  @spec do_parse_green_branch([stop_with_bubble_info], [RouteStop.t],
                              {[stop_with_bubble_info], [RouteStop.t]},
                              0 | 1) :: {[stop_with_bubble_info], [RouteStop.t]}
  defp do_parse_green_branch([], [%RouteStop{branch: "Green-E"}|_] = e_stops, {all_branch_stops, all_shared_stops}, 1) do
    # this clunkiness is the best way I could think of to insert
    # the E line stops at the right location when direction_id is 1 :(
    {kenmore_hynes, rest} = Enum.split_while(all_shared_stops, & &1.id != "place-coecl")
    {all_branch_stops, List.flatten([kenmore_hynes, e_stops, rest])}
  end
  defp do_parse_green_branch(branch_stops, shared_stops, {all_branch_stops, all_shared_stops}, 1) do
    {branch_stops ++ all_branch_stops, all_shared_stops ++ shared_stops}
  end
  defp do_parse_green_branch(branch_stops, shared_stops, {all_branch_stops, all_shared_stops}, 0) do
    {all_branch_stops ++ branch_stops, shared_stops ++ all_shared_stops}
  end

  @doc """
  Appends a branch's stops to the full list of stops for the route. Each stop gets stop bubble information for all
  branches that the stop needs to have a graphic for. Returns a tuple of {stops_with_bubble_info, previous_branches}
  so that the next stop can map over the list of branches in order to generate the correct number of bubbles for a stop.

  Stops will be in reverse order. Not used by the Green Line.
  """
  @spec build_branched_stop_list(RouteStops.t, {[stop_with_bubble_info], [branch_name]}) ::
                                                                              {[stop_with_bubble_info], [branch_name]}
  def build_branched_stop_list(%RouteStops{branch: branch, stops: branch_stops}, {all_stops, previous_branches}) do
    previous_branches
    |> update_bubble_branches(branch)
    |> do_build_branched_stop_list(branch, branch_stops, all_stops)
  end

  @spec do_build_branched_stop_list([branch_name], branch_name, [Stops.RouteStop.t],
                                    [stop_with_bubble_info]) :: {[stop_with_bubble_info], [branch_name]}
  defp do_build_branched_stop_list(branch_names, current_branch, branch_stops, all_stops) do
    stop_list = branch_stops
    |> Util.EnumHelpers.with_first_last()
    |> Enum.reduce(all_stops, &build_branched_stop(&1, &2, {current_branch, branch_names}))

    {stop_list, branch_names}
  end

  @doc """
  Builds stop bubble information for a stop, and adds the stop to the list of all stops
  as a tuple of {stop_bubbles, %RouteStop{}}.
  """
  @spec build_branched_stop(RouteStop.t | {RouteStop.t, boolean}, [stop_with_bubble_info],
                              {branch_name, [branch_name]}) :: [stop_with_bubble_info]
  def build_branched_stop(this_stop, all_stops, current_and_previous_branches)
  def build_branched_stop(stop, branch_stops, {_, ["Green" <> _ | _] = green_branches}) do
    # Green Line always evaluates all branches on all stops. If the stop should have a bubble for a branch,
    # &stop_bubble_type/3 returns a valid tuple, otherwise it returns false. The bubble list then gets filtered to
    # remove anything that's not a tuple.
    bubble_types = green_branches
    |> Enum.map(&stop_bubble_type(&1, stop))
    |> Enum.filter(&is_tuple/1)
    [{bubble_types, stop} | branch_stops]
  end
  def build_branched_stop({%RouteStop{is_terminus?: true} = stop, _}, all_stops, {nil, _}) do
    # a terminus that's not on a branch is always :terminus
    [{[{nil, :terminus}], stop} | all_stops]
  end
  def build_branched_stop({%RouteStop{is_terminus?: false} = stop, true}, all_stops, {nil, branches}) do
    # If the first or last unbranched stop on a branched route is not a terminus, it's a merge stop.
    # We identify these in order to know where to render the horizontal line connecting a branch to the main line.
    [{Enum.map(branches, & {&1, :merge}), stop} | all_stops]
  end
  def build_branched_stop({%RouteStop{} = stop, _}, all_stops, {nil, _}) do
    # all other unbranched stops are just :stop
    [{[{nil, :stop}], stop} | all_stops]
  end
  def build_branched_stop({%RouteStop{} = stop, _}, all_stops, {current_branch, branches})
  when is_binary(current_branch) do
    # when the branch name is not nil, that means that the stop is on a branch. The stop needs to show a bubble for
    # each branch that has already been parsed. We evaluate each branch to determine which bubble type to show:
    # - :terminus if this stop IS on that branch and this stop IS a terminus
    # - :stop if this stop IS on that branch and this stop IS NOT a terminus
    # - :line if this stop IS NOT on that branch
    bubble_types = Enum.map(branches, &stop_bubble_type(&1, stop))
    [{bubble_types, stop} | all_stops]
  end

  @doc """
  Adds or removes a branch name to the list of branch names used to build the stop bubbles. Not used by Green Line.
  """
  @spec update_bubble_branches([branch_name], branch_name) :: [branch_name]
  def update_bubble_branches(previous_branches, nil), do: previous_branches
  def update_bubble_branches(previous_branches, branch), do: previous_branches ++ [branch]

  @doc """
  Returns a tuple with the stop bubble type, and the name of the branch that the bubble represents.
  """
  @spec stop_bubble_type(String.t, RouteStop.t) :: {String.t, stop_bubble_type}
  def stop_bubble_type(bubble_branch_name, stop)
  def stop_bubble_type(branch_id, %RouteStop{branch: branch_id, is_terminus?: true}), do: {branch_id, :terminus}
  def stop_bubble_type(branch_id, %RouteStop{branch: branch_id, is_terminus?: false}), do: {branch_id, :stop}
  def stop_bubble_type("Green-E", %RouteStop{id: id}) when id in ["place-kencl", "place-hymnl"], do: nil
  def stop_bubble_type(branch_id, %RouteStop{branch: "Green-E"}) when branch_id != "Green-E", do: {branch_id, :line}
  def stop_bubble_type("Green-" <> branch_letter, %RouteStop{branch: "Green-" <> stop_letter}) when branch_letter < stop_letter,
      do: {"Green-" <> branch_letter, :line}
  def stop_bubble_type("Green-" <> _ = branch_id, stop) do
    cond do
      GreenLine.terminus?(stop.id, branch_id) -> {branch_id, :terminus}
      Enum.member?(GreenLine.excluded_shared_stops(branch_id), stop.id) && branch_id != "Green-E" -> {branch_id, :empty}
      Enum.member?(GreenLine.shared_stops(), stop.id) -> {branch_id, :stop}
      true -> nil # if nothing has matched by this point, the stop should not have any graphic for this branch.
                  # The full list of bubble types for each stop gets filtered later to remove these values.
    end
  end
  def stop_bubble_type(branch_id, _stop), do: {branch_id, :line}

  @doc """
  Sorts branches and their stops into the correct order to prepare them to be parsed.
  """
  @spec sort_branches([Stops.RouteStops.t], direction_id) :: [Stops.RouteStops.t]
  def sort_branches(branches, 0), do: Enum.reduce(branches, [], & [%{&1 | stops: Enum.reverse(&1.stops)} | &2])
  def sort_branches(branches, 1), do: branches

  @doc """
  Takes the final generated list of all stops for the route and sorts them into the correct order based on direction id.
  """
  @spec sort_stop_list({[Stops.RouteStop.t], [branch_name]} | [Stops.RouteStop.t], direction_id) :: [Stops.RouteStop.t]
  def sort_stop_list({all_stops, _branches}, direction_id), do: sort_stop_list(all_stops, direction_id)
  def sort_stop_list(all_stops, 1) when is_list(all_stops), do: Enum.reverse(all_stops)
  def sort_stop_list(all_stops, 0) when is_list(all_stops), do: all_stops

  @spec dynamic_map_data(String.t, [String.t], {[Stops.Stop.t], any}, map()) :: map()
  defp dynamic_map_data(color, polylines, {stops, _shapes}, vehicle_tooltips) do
    %{
      color: color,
      polylines: polylines,
      stops: Enum.map(stops, &([&1.latitude, &1.longitude, &1.name, &1.id])),
      stops_show_marker: true,
      stop_icon: static_url(Site.Endpoint, "/images/map-#{color}-dot-icon.png"),
      vehicles: map_vehicles(vehicle_tooltips),
      vehicle_icon: static_url(Site.Endpoint, "/images/map-#{color}-vehicle-icon.png"),
      options: %{
        gestureHandling: "cooperative",
        streetViewControl: false,
        mapTypeControl: false
      }
    }
  end

  @spec map_vehicles(nil | map()) :: []
  def map_vehicles(nil), do: []
  def map_vehicles(vehicle_tooltips) do
    vehicle_tooltips
    |> Enum.reduce([], fn({key, tooltip_data}, output) ->
      case key do
        {_, _} -> output
        _ -> [[tooltip_data.vehicle.latitude,
               tooltip_data.vehicle.longitude,
               VehicleTooltip.tooltip(tooltip_data)] | output]
      end
    end)
  end
end
