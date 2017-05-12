defmodule Site.ScheduleV2View.StopList do
  use Site.Web, :view

  @type stop_bubble_type :: :stop | :terminus | :line | :empty | :merge

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

  @doc """
  Determines whether a stop is the first stop of its branch that is shown on the page, and
  therefore should display a link to expand/collapse the branch.
  """
  @spec add_expand_link?(Stops.RouteStop.t, [Stops.RouteStops.t]) :: boolean
  def add_expand_link?(%Stops.RouteStop{branch: nil}, _), do: false
  def add_expand_link?(%Stops.RouteStop{id: stop_id, branch: branch}, branches) do
    case Map.get(branches, branch) do
      [^stop_id|_] -> true
      _ -> false
    end
  end

  @doc """
  Returns the content for an individual stop bubble in a stop list. The content and styles vary depending on
  whether the stop is a terminus, the branch is expanded, the row is a button to expand the branch, etc.
  """
  @spec stop_bubble_content(map, stop_bubble_type, String.t, boolean) :: Phoenix.HTML.Safe.t
  def stop_bubble_content(%{is_expand_link?: true} = assigns, _, branch, _) do
    [render_stop_bubble_line(:line, {branch, assigns.expanded}, {assigns.route, assigns.stop})]
  end
  def stop_bubble_content(assigns, :merge, branch, 0) do
    [
      render_stop_bubble(:stop, assigns.route, 0, assigns.show_vehicle?),
      render_stop_bubble_line(:merge, {branch, assigns.expanded}, {assigns.route, assigns.stop})
    ]
  end
  def stop_bubble_content(assigns, :merge, branch, _) do
    line_type = stop_bubble_line_type(:merge, {branch, assigns.expanded}, {assigns.route, assigns.stop})
    [
      content_tag(:div, "", class: "route-branch-indent-start #{line_type}"),
      do_render_stop_bubble_line(line_type)
    ]
  end
  def stop_bubble_content(assigns, bubble_type, branch, index) do
    [
      render_stop_bubble(bubble_type, assigns.route, index, assigns.show_vehicle?),
      render_stop_bubble_line(bubble_type, {branch, assigns.expanded}, {assigns.route, assigns.stop})
    ]
  end

  @doc """
  Renders a stop bubble, if one should be rendered.
  """
  @spec render_stop_bubble(stop_bubble_type, Routes.Route.t, integer, boolean) :: Phoenix.HTML.Safe.t
  def render_stop_bubble(bubble_type, route, index, show_vehicle?)
  def render_stop_bubble(bubble_type, %Routes.Route{id: "Green"} = route, index, show_vehicle?)
      when bubble_type in [:stop, :terminus] do
    stop_bubble_location_display(show_vehicle?,
                                 %{route | id: Enum.at(GreenLine.branch_ids(), index)},
                                 bubble_type == :terminus)
  end
  def render_stop_bubble(bubble_type, %Routes.Route{} = route, _, show_vehicle?) when bubble_type in [:stop, :terminus] do
    stop_bubble_location_display(show_vehicle?, route, bubble_type == :terminus)
  end
  def render_stop_bubble(_, %Routes.Route{}, _, _), do: ""

  defp render_stop_bubble_line(bubble_type, {expanded_branch, branch}, {route, stop}) do
    bubble_type
    |> stop_bubble_line_type({expanded_branch, branch}, {route, stop})
    |> do_render_stop_bubble_line()
  end

  defp do_render_stop_bubble_line(nil), do: ""
  defp do_render_stop_bubble_line(class) do
    content_tag(:div, "", class: "route-branch-stop-bubble-line #{class}")
  end

  @doc """
  Renders the line below a stop bubble, if one should be rendered.
  Uses the bubble_type of the stop bubble and checks some additional logic to determine what to return.

  Uses the following logic for the bubble types:
    :terminus
      - solid line if the stop is the first stop in the list
      - solid line if the route is "Green" and the stop's branch is nil
      - everything else: no line

    :line
      - solid line if the bubble's branch is expanded
      - dotted line if the bubble's branch is collapsed
      - solid line if the stop's branch is nil
          (^^ only used by the Green line)

    :stop when route has branches and the route is NOT "Green"
      - solid line if the stop's branch is nil
      - solid line if the stop's branch is NOT nil and the bubble's branch is expanded
      - dotted line if the stop's branch is NOT nil and the bubble's branch is NOT expanded

    :stop when route is "Green"
      - solid line if the bubble's branch IS expanded
      - solid line if: the bubble's branch IS NOT expanded
                        AND the stop's branch IS nil
                        AND the bubble's branch IS NOT "Green-E"
      - solid line if: the bubble's branch IS NOT expanded
                       AND the stop's branch IS NOT nil

      - dotted line if: the stop's branch is nil
                          AND the bubble's branch IS "Green-E"
                          AND the E line IS NOT expanded

    :stop when route IS green
      - if the stop's branch is nil AND the bubble's branch is collapsed

    :merge (the last unbranched stop on a route -- displays a line for both branches even though it's not on a branch)
      - solid line if the branch is expanded
      - dotted line if the branch is collapsed

  """
  @spec stop_bubble_line_type(stop_bubble_type, {String.t, String.t},
                                                {Routes.Route.t, Stops.RouteStop.t}) :: :solid | :dotted | :hidden
  def stop_bubble_line_type(bubble_type, branch_info, route_stop_info)
  def stop_bubble_line_type(:empty, _, _), do: nil
  def stop_bubble_line_type(:terminus, _, {_route, %Stops.RouteStop{stop_number: 0}}), do: :solid
  def stop_bubble_line_type(:terminus, _, {%Routes.Route{id: "Green"}, %Stops.RouteStop{branch: nil}}), do: :solid
  def stop_bubble_line_type(:terminus, _, _), do: nil
  def stop_bubble_line_type(:line, {expanded, expanded}, _), do: :solid
  def stop_bubble_line_type(:line, _, {_, %Stops.RouteStop{branch: nil}}), do: :solid
  def stop_bubble_line_type(:line, {"Green-" <> _ = bubble_branch, _}, {_, %Stops.RouteStop{branch: "Green-E"}})
      when bubble_branch != "Green-E", do: :solid
  def stop_bubble_line_type(:line, _, _), do: :dotted
  def stop_bubble_line_type(:merge, {expanded, expanded}, _), do: :solid
  def stop_bubble_line_type(:merge, _, _), do: :dotted
  def stop_bubble_line_type(:stop, {expanded, expanded}, _), do: :solid
  def stop_bubble_line_type(:stop, _, {%Routes.Route{id: route_id}, %Stops.RouteStop{branch: nil}})
      when route_id != "Green", do: :solid
  def stop_bubble_line_type(:stop, _, {%Routes.Route{id: route_id}, _}) when route_id != "Green", do: :solid
  def stop_bubble_line_type(:stop, {branch, _}, {%Routes.Route{id: "Green"}, %Stops.RouteStop{branch: nil, id: stop_id}}) do
    case GreenLine.merge_id(branch) do
      ^stop_id -> :dotted
      _ -> :solid
    end
  end

  @doc """
  Given a Vehicle and a route, returns an icon for the route. Given nil, returns nothing. Adds a
  class to indicate that the vehicle is at a trip endpoint if the third parameter is true.
  """
  @spec stop_bubble_location_display(boolean, Routes.Route.t, boolean) :: Phoenix.HTML.Safe.t
  def stop_bubble_location_display(vehicle?, route, terminus?)
  def stop_bubble_location_display(true, route, true) do
    svg_icon_with_circle(%SvgIconWithCircle{icon: Routes.Route.type_atom(route.type), class: "icon-inverse", show_tooltip?: false})
  end
  def stop_bubble_location_display(true, route, false) do
    svg_icon_with_circle(%SvgIconWithCircle{icon: Routes.Route.type_atom(route.type), class: "icon-boring", show_tooltip?: false})
  end
  def stop_bubble_location_display(false, route, true) do
    stop_bubble_icon(:terminus, route.id)
  end
  def stop_bubble_location_display(false, route, false) do
    stop_bubble_icon(:stop, route.id)
  end

  defp stop_bubble_icon(class, route_id) do
    content_tag :svg, viewBox: "0 0 42 42", class: "icon stop-bubble-#{class}" do
      [
        content_tag(:circle, "", r: 20, cx: 20, cy: 20, transform: "translate(2,2)"),
        case route_id do
          "Green-" <> branch -> content_tag(:text, branch, font_size: 24, x: 14, y: 30)
          _ -> ""
        end
      ]
    end
  end

  @doc """
  Link to expand or collapse a route branch.
  """
  @spec view_branch_link(Plug.Conn.t, String.t | nil, String.t) :: Phoenix.HTML.Safe.t
  def view_branch_link(conn, "Green-" <> letter, "Green-" <> letter) do
    do_branch_link(conn, nil, letter, :hide)
  end
  def view_branch_link(conn, _, "Green-" <> letter) do
    do_branch_link(conn, "Green-" <> letter, letter, :view)
  end
  def view_branch_link(conn, branch_name, branch_name) do
    do_branch_link(conn, nil, branch_name, :hide)
  end
  def view_branch_link(conn, _, branch_name) do
    do_branch_link(conn, branch_name, branch_name, :view)
  end

  @spec do_branch_link(Plug.Conn.t, String.t | nil, String.t, :hide | :view) :: Phoenix.HTML.Safe.t
  defp do_branch_link(conn, expanded, branch_name, action) do
    {action_text, caret} = case action do
                             :hide -> {"Hide ", "up"}
                             :view -> {"View ", "down"}
                           end
    link to: update_url(conn, expanded: expanded), class: "branch-link" do
      [content_tag(:span, action_text, class: "hidden-sm-down"), branch_name, " Branch ", fa("caret-#{caret}")]
    end
  end

end
