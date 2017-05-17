defmodule Site.ScheduleV2Controller.Line do

  import Plug.Conn, only: [assign: 3]
  import Site.Router.Helpers
  require Routes.Route

  @type stop_bubble_type :: :stop | :terminus | :line | :empty | :merge

  def init([]), do: []

  def call(%Plug.Conn{assigns: %{route: route}} = conn, _args) do
    # always use outbound direction, except for buses
    conn = if route.type == 3, do: conn, else: assign(conn, :direction_id, 0)
    all_shapes = get_all_shapes(route.id, conn.assigns.direction_id)
    active_shapes = get_active_shapes(all_shapes, route, conn.query_params["variant"], conn.query_params["expanded"])

    branches = get_branches(all_shapes, active_shapes, route, conn.assigns.direction_id)
    map_img_src = branches
    |> get_map_data({all_shapes, active_shapes}, route.id, conn.query_params["expanded"])
    |> map_img_src(route)

    collapsed_branches = remove_collapsed_stops(branches, conn.query_params["expanded"])

    conn
    |> assign(:all_stops, build_stop_list(collapsed_branches))
    |> assign(:expanded, conn.query_params["expanded"])
    |> assign(:branches, collapsed_branches)
    |> assign(:all_shapes, all_shapes)
    |> assign(:active_shape, if route.type == 3 do List.first(active_shapes) else nil end)
    |> assign(:map_img_src, map_img_src)
  end

  @doc """
  """
  def get_all_shapes("Green", direction_id) do
    GreenLine.branch_ids()
    |> Enum.map(& Task.async(fn -> get_all_shapes(&1, direction_id) end))
    |> Enum.flat_map(&Task.await/1)
  end
  def get_all_shapes(route_id, direction_id) do
    Routes.Repo.get_shapes(route_id, direction_id)
  end

  @doc """
  Gets a list of RouteStops representing all of the branches on the route. Routes without branches will have
  """
  def get_branches(all_shapes, _active_shape, %Routes.Route{id: "Green"}, _direction_id) do
    GreenLine.branch_ids()
    |> Enum.map(&get_green_branch(&1, all_shapes))
    |> Enum.map(&Task.await/1)
    |> Enum.reverse()
  end
  def get_branches(_, active_shapes, %Routes.Route{type: 3} = route, direction_id) do
    do_get_branches(active_shapes, route, direction_id)
  end
  def get_branches(all_shapes, _, route, direction_id), do: do_get_branches(all_shapes, route, direction_id)

  defp do_get_branches(shapes, route, direction_id) do
    route.id
    |> Stops.Repo.by_route(direction_id)
    |> Stops.RouteStops.by_direction(shapes, route, direction_id)
  end

  defp get_green_branch(branch_id, shapes) do
    Task.async(fn ->
      %{0 => headsigns} = Routes.Repo.headsigns(branch_id)
      branch = shapes
      |> Enum.filter(& Enum.member?(headsigns, &1.name))
      |> get_branches([], %Routes.Route{id: branch_id, type: 0}, 0)
      |> List.first()
      %{branch | branch: branch_id, stops: Enum.map(branch.stops, & %{&1 | branch: branch_id})}
    end)
  end

  defp remove_collapsed_stops([all_stops], _), do: [all_stops]
  defp remove_collapsed_stops(branches, expanded) do
    Enum.map(branches, & do_remove_collapsed_stops(&1, expanded))
  end

  defp do_remove_collapsed_stops(%Stops.RouteStops{branch: nil} = branch, _), do: branch
  defp do_remove_collapsed_stops(%Stops.RouteStops{branch: branch_id} = branch, branch_id), do: branch
  defp do_remove_collapsed_stops(%Stops.RouteStops{branch: "Green-" <> _} = branch, _) do
    {shared, not_shared} = Enum.split_while(branch.stops, & &1.id != GreenLine.split_id(branch.branch))
    %{branch | stops: shared ++ [List.last(not_shared)]}
  end
  defp do_remove_collapsed_stops(%Stops.RouteStops{} = branch, _) do
    %{branch | stops: [List.last(branch.stops)]}
  end

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

  defp get_requested_shape(_shapes, nil), do: nil
  defp get_requested_shape(shapes, variant), do: Enum.find(shapes, &(&1.id == variant))

  defp get_default_shape(nil, [default | _]), do: [default]
  defp get_default_shape(shape, _shapes), do: [shape]

  defp get_map_data(branches, {all_shapes, _active_shapes}, "Green", nil) do
    {get_map_stops(branches), all_shapes}
  end
  defp get_map_data(branches, {all_shapes, _active_shapes}, "Green", branch_id) do
    stops = branches |> Enum.filter(& &1.branch == branch_id) |> get_map_stops()
    {stops, all_shapes}
  end
  defp get_map_data(branches, {_all_shapes, active_shapes}, _route_id, _expanded) do
    {get_map_stops(branches), active_shapes}
  end

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
  @spec map_img_src({[Stops.Stop.t], [Routes.Shape.t] | [nil]}, Routes.Route.t) :: String.t
  def map_img_src(_, %Routes.Route{type: 4}) do
    static_url(Site.Endpoint, "/images/ferry-spider.jpg")
  end
  def map_img_src({stops, shapes}, route) do
    shapes
    |> Enum.flat_map(& PolylineHelpers.condense([&1.polyline]))
    |> Enum.map(&{:path, "color:0x#{map_color(route.type, route.id)}FF|enc:#{&1}"})
    |> do_map_img_src(stops, route)
  end

  defp do_map_img_src(paths, stops, route) do
    opts = paths ++ [
      markers: markers(stops, route.type, route.id)
    ]
    GoogleMaps.static_map_url(600, 600, opts)
  end

  @spec map_color(String.t, String.t) :: String.t
  defp map_color(3, _id), do: "FFCE0C"
  defp map_color(2, _id), do: "A00A78"
  defp map_color(_type, "Blue"), do: "0064C8"
  defp map_color(_type, "Red"), do: "FF1428"
  defp map_color(_type, "Mattapan"), do: "FF1428"
  defp map_color(_type, "Orange"), do: "FF8200"
  defp map_color(_type, "Green"), do: "428608"
  defp map_color(_type, _id), do: "0064C8"

  defp markers(stops, type, id) do
    ["anchor:center",
     "icon:#{icon_path(type, id)}",
     path(stops)]
    |> Enum.join("|")
  end

  defp path(stops) do
    stops
    |> Enum.map(&position_string/1)
    |> Enum.join("|")
  end

  defp position_string(%{latitude: latitude, longitude: longitude}) do
    "#{Float.floor(latitude, 4)},#{Float.floor(longitude, 4)}"
  end

  defp icon_path(type, id) do
    static_url(Site.Endpoint, "/images/map-#{map_color(type, id)}-dot-icon.png")
  end

  @doc """
  Builds a list of all stops on a route. The stops are represented by tuples of {`bubble_types`, %RouteStop{}} where
  `bubble_types` is a list of atoms representing the number and type of bubbles to display on that stop's row.
  """
  @spec build_stop_list([Stops.RouteStops.t]) :: [{[stop_bubble_type], Stops.RouteStop.t}]
  def build_stop_list([%Stops.RouteStops{branch: "Green-" <> _}|_] = branches) do
    {before_split, after_split} = branches
    |> Enum.reduce([], &build_green_stop_list/2)
    |> Enum.split_while(fn {_, stop} -> stop.id != "place-coecl" end)

    after_split = Enum.map(after_split, fn
      {bubbles, %Stops.RouteStop{id: id} = stop} when id in ["place-coecl", "place-hymnl", "place-kencl"] -> {bubbles, %{stop | branch: nil}}
      stop_tuple -> stop_tuple
    end)

    before_split
    |> Enum.map(&parse_shared_green_stops/1)
    |> Kernel.++(after_split)
  end
  def build_stop_list([%Stops.RouteStops{stops: stops}]) do
    stops
    |> Util.EnumHelpers.with_first_last()
    |> Enum.map(fn {stop, is_terminus?} ->
      bubble_type = if is_terminus?, do: :terminus, else: :stop
      {[bubble_type], %{stop | branch: nil}}
    end)
  end
  def build_stop_list(branches) do
    branches
    |> Enum.reverse()
    |> Enum.reduce({[], []}, &build_branched_stop_list/2)
  end

  # for Green Line stops before Copley, replaces :line bubble type with :empty so that there will be
  # a placeholder div but no actual bubble, and sets the stop's branch to nil so it will be recognized as a shared stop.
  @spec parse_shared_green_stops({[stop_bubble_type], Stops.RouteStop.t}) :: {[stop_bubble_type], Stops.RouteStop.t}
  defp parse_shared_green_stops({bubble_types, stop}) do
    bubble_types = Enum.map(bubble_types, fn
                                            :line -> :empty
                                            type -> type
                                          end)
    {bubble_types, %{stop | branch: nil}}
  end

  # appends the stops from a green line branch onto the full list of stops on the green line.
  @spec build_green_stop_list(Stops.RouteStops.t, [Stops.RouteStop.t]) :: [Stops.RouteStop.t]
  defp build_green_stop_list(%Stops.RouteStops{stops: branch_stops}, all_stops) do
    branch_stop_ids = Enum.map(branch_stops, & &1.id)

    all_stops
    |> Kernel.++(Enum.map(branch_stops, & {[], &1}))
    |> Enum.uniq_by(fn {_, stop} -> stop.id end)
    |> Enum.map(fn {bubble_types, stop} ->
      bubble_type = branch_stop_ids |> Enum.member?(stop.id) |> stop_bubble_type(stop.is_terminus?, false)
      {[bubble_type | bubble_types], stop}
    end)
  end

  defp build_branched_stop_list(%Stops.RouteStops{branch: nil, stops: [first_stop|stops]}, {all_stops, [_,_]}) do
    first_stop = {[:terminus], first_stop}
    last_stop = {[:merge, :merge], List.last(stops)}
    middle_stops = stops |> Enum.slice(0..-2) |> Enum.map(&build_unbranched_stop/1)
    [first_stop] ++ middle_stops ++ [last_stop] ++ all_stops
  end
  defp build_branched_stop_list(%Stops.RouteStops{branch: branch, stops: branch_stops}, {all_stops, previous_branches}) do
    branches = [branch | previous_branches]
    updated_stop_list = branch_stops
    |> Enum.reverse()
    |> Enum.reduce(all_stops, & build_branch_stop(&1, branches, &2))
    {updated_stop_list, branches}
  end

  defp build_unbranched_stop(stop) do
    {[:stop], stop}
  end

  defp build_branch_stop(stop, branches, all_stops) do
    bubble_types = branches
    |> Enum.reverse()
    |> Enum.map(&stop_bubble_type(&1 == stop.branch, stop.is_terminus?, stop.branch == nil && length(branches) == 2))
    [{bubble_types, stop} | all_stops]
  end

  defp stop_bubble_type(stop_is_on_branch?, stop_is_terminus?, is_merge_stop?)
  defp stop_bubble_type(_, _, true), do: :merge
  defp stop_bubble_type(true, true, _), do: :terminus
  defp stop_bubble_type(true, false, _), do: :stop
  defp stop_bubble_type(_, _, _), do: :line
end
