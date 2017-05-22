defmodule Site.ScheduleV2View.StopList do
  use Site.Web, :view

  alias Site.ScheduleV2Controller.Line, as: LineController

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
  @spec stop_bubble_content(map, LineController.stop_bubble_type, String.t, boolean) :: Phoenix.HTML.Safe.t
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
  @spec render_stop_bubble(LineController.stop_bubble_type, Routes.Route.t, integer, boolean) :: Phoenix.HTML.Safe.t
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
  @spec stop_bubble_line_type(LineController.stop_bubble_type, {String.t, String.t},
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
  def stop_bubble_line_type(:stop, _, _), do: :solid

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

  @doc """
  Builds a stop bubble SVG (without vehicle). Includes the branch letter for green line stops. For a stop bubble
  with a vehicle icon, use `stop_bubble_location_display/3`
  """
  @spec stop_bubble_icon(LineController.stop_bubble_type, Routes.Route.id_t, String.t) :: Phoenix.Html.Safe.t
  def stop_bubble_icon(class, route_id, opts \\ []) do
    icon_opts = Keyword.merge([icon_class: "", transform: "translate(2,2)"], opts)
    content_tag :svg, viewBox: "0 0 42 42", class: "icon stop-bubble-#{class} #{icon_opts[:icon_class]}" do
      [
        content_tag(:circle, "", r: 20, cx: 20, cy: 20, transform: "#{icon_opts[:transform]}"),
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

  @doc """
  Sets the direction_id for the "Schedules from here" link. Chooses the opposite of the current direction only for the last stop
  on the line or branch (since there are no trips in that direction from those stops).
  """
  @spec schedule_link_direction_id(Stops.RouteStop.t, [{LineController.stop_bubble_type, String.t}], 0 | 1) :: 0 | 1
  def schedule_link_direction_id(stop, bubbles, direction_id) do
    bubbles
    |> Enum.map(& elem(&1, 0))
    |> Enum.member?(:terminus)
    |> do_schedule_link_direction_id(stop, direction_id)
  end

  @spec do_schedule_link_direction_id(boolean, Stops.RouteStop.t, 0 | 1) :: 0 | 1
  defp do_schedule_link_direction_id(true, %Stops.RouteStop{stop_number: stop}, direction_id) when stop != 0 do
    if direction_id == 0, do: 1, else: 0
  end
  defp do_schedule_link_direction_id(_is_terminus, _stop, direction_id), do: direction_id
end
