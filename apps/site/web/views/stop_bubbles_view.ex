defmodule Site.StopBubblesView do
  use Site.Web, :view

  import VehicleHelpers, only: [tooltip: 1]
  alias Stops.RouteStop
  alias Routes.Route

  @doc """
  Returns the content for an individual stop bubble in a stop list. The content and styles vary depending on
  whether the stop is a terminus, the branch is expanded, the row is a button to expand the branch, etc.
  """
  @spec stop_bubble_content(map, {String.t, LineController.stop_bubble_type}) :: Phoenix.HTML.Safe.t
  def stop_bubble_content(assigns, bubble_info)
  def stop_bubble_content(%{is_expand_link?: true} = assigns, {bubble_branch, bubble_type_}) do
    bubble_type = if Enum.member?([:stop, :terminus], bubble_type_), do: :line, else: bubble_type_
    [render_stop_bubble_line(bubble_type, bubble_branch, assigns)]
  end
  def stop_bubble_content(%{route: %Routes.Route{id: "Green"}} = assigns, {branch, :terminus}) do
    [
      render_stop_bubble(:terminus, assigns.route, branch, assigns[:vehicle_tooltip]),
      render_stop_bubble_line(:terminus, branch, assigns)
    ]
  end
  def stop_bubble_content(%{stop: %RouteStop{stop_number: 0}} = assigns, {branch, :terminus}) do
    [
      render_stop_bubble(:terminus, assigns.route, branch, assigns[:vehicle_tooltip]),
      render_stop_bubble_line(:terminus, branch, assigns)
    ]
  end
  def stop_bubble_content(%{stop: %RouteStop{stop_number: _}} = assigns, {branch, :terminus}) do
    [render_stop_bubble(:terminus, assigns.route, branch, assigns[:vehicle_tooltip])]
  end
  def stop_bubble_content(assigns, {branch, :terminus}) do
    [render_stop_bubble(:terminus, assigns.route, branch, assigns[:vehicle_tooltip])]
  end
  def stop_bubble_content(%{bubble_index: 0} = assigns, {branch, :merge}) do
    [
      render_stop_bubble(:stop, assigns.route, branch, assigns[:vehicle_tooltip]),
      render_stop_bubble_line(:merge, branch, assigns)
    ]
  end
  def stop_bubble_content(%{direction_id: 1} = assigns, {branch, :merge}) do
    [
      render_stop_bubble_line(:merge, branch, assigns),
      content_tag(:div, "", class: "route-branch-indent-start #{stop_bubble_line_type(:merge, branch, assigns)}")
    ]
  end
  def stop_bubble_content(assigns, {branch, :merge}) do
    [
      content_tag(:div, "", class: "merge-stop-spacer"),
      content_tag(:div, "", class: "route-branch-indent-start #{stop_bubble_line_type(:merge, branch, assigns)}"),
      render_stop_bubble_line(:merge, branch, assigns)
    ]
  end
  def stop_bubble_content(assigns, {branch, bubble_type}) when is_binary(branch) or is_nil(branch) do
    [
      render_stop_bubble(bubble_type, assigns.route, branch, assigns[:vehicle_tooltip]),
      render_stop_bubble_line(bubble_type, branch, assigns)
    ]
  end

  @spec render_stop_bubble(LineController.stop_bubble_type, Route.t, String.t, VehicleTooltip.t | nil)
        :: Phoenix.HTML.Safe.t
  defp render_stop_bubble(bubble_type, %Route{id: "Green"} = route, branch, vehicle_tooltip)
  when bubble_type in [:stop, :terminus] do
    stop_bubble_location_display(vehicle_tooltip, %{route | id: branch}, bubble_type == :terminus)
  end
  defp render_stop_bubble(bubble_type, %Route{} = route, _, vehicle_tooltip)
  when bubble_type in [:stop, :terminus] do
      stop_bubble_location_display(vehicle_tooltip, route, bubble_type == :terminus)
  end
  defp render_stop_bubble(_, %Route{}, _, _), do: ""

  defp render_stop_bubble_line(bubble_type, bubble_branch, assigns) do
    bubble_type
    |> stop_bubble_line_type(bubble_branch, assigns)
    |> do_render_stop_bubble_line(assigns.direction_id)
  end

  defp do_render_stop_bubble_line(nil, _), do: ""
  defp do_render_stop_bubble_line(class, direction_id) do
    content_tag(:div, "", class: "route-branch-stop-bubble-line #{class} direction-#{direction_id}")
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
  @spec stop_bubble_line_type(LineController.stop_bubble_type, String.t, map) :: :solid | :dotted | :hidden
  def stop_bubble_line_type(bubble_type, branch_name, assigns)
  def stop_bubble_line_type(:empty, _, _), do: nil
  def stop_bubble_line_type(:terminus, _, %{stop: %RouteStop{branch: "Green-" <> branch},
                                            expanded: "Green-" <> branch,
                                            direction_id: 1}), do: :solid
  def stop_bubble_line_type(:terminus, branch, %{stop: %RouteStop{branch: "Green-E"}}) when branch != "Green-E", do: :solid
  def stop_bubble_line_type(:terminus, _, %{stop: %RouteStop{branch: "Green-" <> _}, direction_id: 1}), do: :dotted
  def stop_bubble_line_type(:terminus, "Green-" <> _, %{stop: %RouteStop{branch: nil}, direction_id: 0}), do: :solid
  def stop_bubble_line_type(:terminus, "Green-" <> _, _), do: nil
  def stop_bubble_line_type(:terminus, nil, _), do: :solid
  def stop_bubble_line_type(:terminus, branch, %{direction_id: 1, expanded: branch}) when not is_nil(branch), do: :solid
  def stop_bubble_line_type(:terminus, _, _), do: :dotted
  def stop_bubble_line_type(_, branch, %{expanded: branch}), do: :solid
  def stop_bubble_line_type(:line, expanded, %{expanded: expanded}), do: :solid
  def stop_bubble_line_type(:line, "Green-" <> _ = bubble_branch, %{stop: %RouteStop{branch: "Green-E"}})
    when bubble_branch != "Green-E", do: :solid
  def stop_bubble_line_type(:line, _, _), do: :dotted
  def stop_bubble_line_type(:merge, expanded, %{expanded: expanded}), do: :solid
  def stop_bubble_line_type(:merge, _, %{direction_id: 1, bubble_index: 0}), do: :solid
  def stop_bubble_line_type(:merge, _, _), do: :dotted
  def stop_bubble_line_type(:stop, expanded, %{expanded: expanded}), do: :solid
  def stop_bubble_line_type(:stop, _, %{route: %Routes.Route{id: route_id}, stop: %RouteStop{branch: nil}})
      when route_id != "Green", do: :solid
  def stop_bubble_line_type(:stop, _, %{route: %Routes.Route{id: route_id}}) when route_id != "Green", do: :solid
  def stop_bubble_line_type(:stop, "Green" <> _ = branch, %{direction_id: direction,
                                                          stop: %RouteStop{branch: nil, id: stop_id}}) do
    cond do
      stop_id == GreenLine.merge_id(branch) && direction == 0 -> :dotted
      stop_id == GreenLine.split_id(branch) && direction == 1 -> :dotted
      true -> :solid
    end
  end
  def stop_bubble_line_type(:stop, _, _), do: :solid

  @doc """
  Given a Vehicle and a route, returns an icon for the route. Given nil, returns nothing. Adds a
  class to indicate that the vehicle is at a trip endpoint if the third parameter is true.
  """
  @spec stop_bubble_location_display(VehicleTooltip.t | nil, Route.t, boolean) :: Phoenix.HTML.Safe.t
  def stop_bubble_location_display(vehicle_tooltip, route, terminus?)
  def stop_bubble_location_display(%VehicleTooltip{vehicle: %Vehicles.Vehicle{route_id: route_id}} = vehicle_tooltip,
                                   %Route{id: route_id, type: route_type}, terminus?) do
    vehicle_bubble(route_type, vehicle_tooltip, terminus?)
  end
  def stop_bubble_location_display(_, route, true) do
    stop_bubble_icon(:terminus, route.id)
  end
  def stop_bubble_location_display(_, route, false) do
    stop_bubble_icon(:stop, route.id)
  end

  @spec vehicle_bubble(0..4, VehicleTooltip.t, boolean) :: Phoenix.HTML.Safe.t
  defp vehicle_bubble(route_type, vehicle_tooltip, true) do
    do_vehicle_bubble(route_type, vehicle_tooltip, "icon-inverse")
  end
  defp vehicle_bubble(route_type, vehicle_tooltip, false) do
    do_vehicle_bubble(route_type, vehicle_tooltip, "icon-boring")
  end

  @spec do_vehicle_bubble(0..4, VehicleTooltip.t, String.t) :: Phoenix.HTML.Safe.t
  defp do_vehicle_bubble(route_type, vehicle_tooltip, class) do
    content_tag(:span,
      svg_icon_with_circle(%SvgIconWithCircle{
        icon: Routes.Route.type_atom(route_type),
        class: class,
        show_tooltip?: false}),
      data: [html: true, toggle: "tooltip", placement: "right"],
      title: tooltip(vehicle_tooltip)
    )
  end

  @doc """
  Builds a stop bubble SVG (without vehicle). Includes the branch letter for green line stops. For a stop bubble
  with a vehicle icon, use `stop_bubble_location_display/3`
  """
  @spec stop_bubble_icon(LineController.stop_bubble_type, Routes.Route.id_t, Keyword.t) :: Phoenix.HTML.Safe.t
  def stop_bubble_icon(class, route_id, opts \\ []) do
    icon_opts = Keyword.merge([icon_class: "", transform: "translate(2,2)"], opts)
    content_tag :svg, viewBox: "0 0 42 42", class: String.trim("icon stop-bubble-#{class} #{icon_opts[:icon_class]}") do
      [
        content_tag(:circle, "", r: 20, cx: 20, cy: 20, transform: "#{icon_opts[:transform]}"),
        case route_id do
          "Green-" <> branch -> content_tag(:text, branch, font_size: 24, x: 14, y: 30)
          _ -> ""
        end
      ]
    end
  end
end
