defmodule Site.ScheduleV2View.StopList do
  use Site.Web, :view

  alias Site.StopBubble
  alias Stops.{RouteStop, RouteStops}

  @doc """
  Determines whether a stop is the first stop of its branch that is shown on the page, and
  therefore should display a link to expand/collapse the branch.
  """
  @spec add_expand_link?(RouteStop.t, map) :: boolean
  def add_expand_link?(%RouteStop{branch: nil}, _assigns), do: false
  def add_expand_link?(_, %{route: %Routes.Route{id: "CR-Kingson"}}), do: false
  def add_expand_link?(%RouteStop{branch: "Green-" <> _ = branch} = stop, assigns) do
    case assigns do
      %{direction_id: 0} -> GreenLine.split_id(branch) == stop.id
      _ -> GreenLine.terminus?(stop.id, branch)
    end
  end
  def add_expand_link?(%RouteStop{id: stop_id, branch: branch}, assigns) do
    case Enum.find(assigns.branches, & &1.branch == branch) do
      %RouteStops{stops: [_]} -> true
      %RouteStops{stops: [%RouteStop{id: ^stop_id}|_]} -> true
      _ -> false
    end
  end

  @doc """
  Link to expand or collapse a route branch.

  Note: The target element (with id `"target_id"`) must also have class `"collapse stop-list"`
  for the javascript to appropriately modify the button and the dotted/solid line
  """
  @spec view_branch_link(Plug.Conn.t, map, String.t) :: Phoenix.HTML.Safe.t
  def view_branch_link(nil, _assigns, _target_id), do: []
  def view_branch_link(branch_name, assigns, target_id) do
    Site.ScheduleV2View.render("_stop_list_expand_link.html",
                               Map.merge(assigns,
                                         %{is_expand_link?: true,
                                           branch_name: branch_name,
                                           target_id: target_id
                                         }))
  end

  @doc """
  Sets the direction_id for the "Schedules from here" link. Chooses the opposite of the current direction only for the last stop
  on the line or branch (since there are no trips in that direction from those stops).
  """
  @spec schedule_link_direction_id(RouteStop.t, [StopBubble.stop_bubble], 0 | 1) :: 0 | 1
  def schedule_link_direction_id(%RouteStop{is_terminus?: true, is_beginning?: false}, _, direction_id) do
    case direction_id do
      0 -> 1
      1 -> 0
    end
  end
  def schedule_link_direction_id(_, _, direction_id), do: direction_id

  def chunk_branches(stops) do
    Enum.chunk_by(stops, fn {_bubbles, stop} -> stop.branch end)
  end

  def separate_collapsible_rows(branch, direction_id) do
    expand_idx = direction_id - 1
    {expand_row, collapsible_stops} = List.pop_at(branch, expand_idx)
    {expand_row, expand_idx, collapsible_stops}
  end

  def render_row(row, assigns) do
    assigns = row_assigns(row, assigns)

    Site.ScheduleV2View.render("_stop_list_row.html", assigns)
  end

  defp row_assigns({bubbles, stop}, assigns) do
    %{
      bubbles: bubbles,
      stop: stop,
      vehicle_tooltip: assigns.vehicle_tooltips[stop.id],
      route: assigns.route,
      direction_id: assigns.direction_id,
      conn: assigns.conn,
      row_content_template: "_line_page_stop_info.html"
    }
  end

  def merge_rows({{_, %{branch: branch}} = expand_row, expand_idx, collapsible_rows}, assigns) do
    collapse_target_id =
      "branch-#{branch}"
      |> String.downcase()
      |> String.replace(" ", "-")

    rendered_expand = render_row(expand_row, assigns)
    rendered_collapse = Enum.map(collapsible_rows, &render_row(&1, assigns))

    case branch do
      nil ->

        List.insert_at(rendered_collapse, expand_idx, rendered_expand)
      _ ->
        [content_tag(:div, [id: collapse_target_id, class: "collapse stop-list"], do: rendered_collapse)]
        |> List.insert_at(expand_idx, rendered_expand)
        |> List.insert_at(assigns.direction_id,
                          view_branch_link(branch, row_assigns(expand_row, assigns), collapse_target_id))
    end
  end

  @spec stop_bubble_row_params(map(), boolean) :: [StopBubble.Params.t]
  def stop_bubble_row_params(assigns, first_stop? \\ true) do
    for {{bubble_branch, bubble_type}, index} <- Enum.with_index(assigns.bubbles) do
      indent = merge_indent(bubble_type, assigns[:direction_id], index)
      class = bubble_class(%{
        bubble_type: bubble_type,
        bubble_branch: bubble_branch,
        direction_id: assigns[:direction_id],
        index: index,
        stop: assigns[:stop],
        bubbles: assigns.bubbles,
        route_id: assigns.route.id,
        is_expand_link?: assigns[:is_expand_link?]
      })

      %StopBubble.Params{
        render_type: rendered_bubble_type(bubble_type, index),
        class: class,
        direction_id: assigns[:direction_id],
        merge_indent: indent,
        route_id: bubble_branch,
        route_type: assigns.route.type,
        show_line?: show_line?(bubble_type, indent, first_stop?),
        vehicle_tooltip: vehicle_tooltip(bubble_type, bubble_branch, assigns.vehicle_tooltip),
        content: bubble_content(bubble_branch),
        bubble_branch: bubble_branch
      }
    end
  end

  defp bubble_class(%{
    bubble_type: bubble_type,
    bubble_branch: bubble_branch,
    direction_id: direction_id,
    index: index,
    stop: stop,
    bubbles: bubbles,
    route_id: route_id,
    is_expand_link?: is_expand_link?
  }) do
    stop_branch = stop && stop.branch

    dotted = if is_dotted(
      dotted_merge(bubble_type, direction_id, index),
      dotted_green(bubble_branch, stop, direction_id),
      dotted_branch(bubbles, stop_branch),
      {route_id, stop_branch},
      is_expand_link?
    ), do: "dotted"

    String.trim("#{bubble_type} #{dotted}")
  end

  defp is_dotted(is_merge, is_green_dotted, is_branch, route_info, is_expand_link?)
  defp is_dotted(_, is_green_dotted, _, {"Green", "Green-E"}, _) do
    is_green_dotted
  end
  defp is_dotted(_, is_green_dotted, is_branch, {"Green", _}, _) do
    is_branch or is_green_dotted
  end
  defp is_dotted(_, _, _, _, true), do: true
  defp is_dotted(is_merge, _, is_branch, _, _) do
    is_merge or is_branch
  end

  defp dotted_merge(:merge, 1, 1), do: true
  defp dotted_merge(:merge, 0, _), do: true
  defp dotted_merge(_, _, _), do: false

  defp dotted_green("Green-E", %RouteStop{id: "place-coecl"}, 0), do: true
  defp dotted_green("Green-E", %RouteStop{branch: "Green-E"}, _), do: true
  defp dotted_green("Green-" <> _ = bubble_branch, %RouteStop{branch: "Green-E"}, _) when bubble_branch != "Green-E" do
    false
  end
  defp dotted_green("Green-" <> _, %RouteStop{id: "place-kencl"}, 0), do: true
  defp dotted_green(_, _, _), do: false

  defp dotted_branch(bubbles, stop_branch) do
    Enum.any?(bubbles, fn {bubble_branch, _type} ->
      is_binary(stop_branch) && stop_branch == bubble_branch
    end)
  end

  defp merge_indent(bubble_type, direction_id, index)
  defp merge_indent(:merge, 0, 1), do: :above
  defp merge_indent(:merge, 1, 1), do: :below
  defp merge_indent(_, _, _), do: nil

  defp show_line?(bubble_type, indent, first_stop?)
  defp show_line?(:empty, _, _), do: false
  defp show_line?(:line, _, _), do: true
  defp show_line?(_, :below, _), do: true
  defp show_line?(:terminus, _, first_stop?), do: first_stop? == true
  defp show_line?(_, _, _), do: true

  defp vehicle_tooltip(bubble_type, bubble_branch, tooltip)
  defp vehicle_tooltip(:line, _, _), do: nil
  defp vehicle_tooltip(_, "Green" <> _ = bubble_branch, %VehicleTooltip{vehicle: %Vehicles.Vehicle{route_id: bubble_branch}} = tooltip), do: tooltip
  defp vehicle_tooltip(_, "Green" <> _, _), do: nil
  defp vehicle_tooltip(_, _, tooltip), do: tooltip

  defp rendered_bubble_type(bubble_type, index)
  defp rendered_bubble_type(:line, _), do: :empty
  defp rendered_bubble_type(:merge, 1), do: :empty
  defp rendered_bubble_type(bubble_type, _), do: bubble_type

  defp bubble_content(route_id)
  defp bubble_content("Green-" <> letter), do: letter
  defp bubble_content(_), do: ""
end
