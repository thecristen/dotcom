defmodule Site.RouteView do
  use Site.Web, :view

  @doc """
  Returns a row for a given stop with all featured icons
  """
  @spec route_row(Plug.Conn.t, Stops.Stop.t, [atom], boolean) :: Phoenix.HTML.Safe.t
  def route_row(conn, stop, stop_features, is_terminus?) do
    content_tag :div, class: "route-stop" do
      [
        stop_bubble(conn.assigns.route.type, is_terminus?),
        stop_name_and_icons(conn, stop, stop_features)
      ]
    end
  end

  @doc """
  Displays a schedule period.
  """
  @spec schedule_period(atom) :: String.t
  def schedule_period(:week), do: "Monday to Friday"
  def schedule_period(period) do
    period
    |> Atom.to_string
    |> String.capitalize
  end

  @spec stop_bubble(integer, boolean) :: Phoenix.HTML.Safe.t
  defp stop_bubble(route_type, is_terminus?) do
    content_tag :div, class: "stop-bubble" do
      Site.ScheduleV2View.stop_bubble_location_display(false, route_type, is_terminus?)
    end
  end

  @spec stop_name_and_icons(Plug.Conn.t, Stops.Stop.t, [atom]) :: Phoenix.HTML.Safe.t
  defp stop_name_and_icons(conn, stop, stop_features) do
    content_tag :div, class: "route-stop-name-icons" do
      [
        content_tag(:div, [class: "name-and-zone"], do: [
          link(break_text_at_slash(stop.name), to: stop_path(conn, :show, stop.id)),
          zone(conn.assigns[:zones], stop)
        ]),
        content_tag(:div, [class: "route-icons"], do: Enum.map(stop_features, &svg_icon_with_circle(%SvgIconWithCircle{icon: &1})))
      ]
    end
  end

  @doc """
  Link to hide a Green/Red line branch.
  """
  @spec hide_branch_link(Plug.Conn.t, String.t) :: Phoenix.HTML.Safe.t
  def hide_branch_link(conn, branch_name) do
    do_branch_link(conn, nil, branch_name, :hide)
  end

  @doc """
  Link to view a Green/Red line branch.
  """
  @spec view_branch_link(Plug.Conn.t, String.t | nil, String.t) :: Phoenix.HTML.Safe.t
  def view_branch_link(conn, expanded, branch_name) do
    do_branch_link(conn, expanded, branch_name, :view)
  end

  @spec do_branch_link(Plug.Conn.t, String.t | nil, String.t, :hide | :view) :: Phoenix.HTML.Safe.t
  defp do_branch_link(conn, expanded, branch_name, action) do
    action_text = case action do
                    :hide -> "Hide "
                    :view -> "View "
                  end
    link to: update_url(conn, expanded: expanded), class: "branch-link" do
      [action_text, branch_name, " Branch ", fa("caret-down")]
    end
  end

  @doc """
  Inline SVG for a Green Line bubble with the branch.
  """
  @spec green_line_bubble(Routes.Route.id_t, atom) :: Phoenix.HTML.Safe.t
  def green_line_bubble(<<"Green-", branch :: binary>>, stop_or_terminus) do
    {div_class, svg_class} = case stop_or_terminus do
                               :stop -> {"", "stop-bubble-stop"}
                               :westbound_terminus -> {"westbound-terminus", "stop-bubble-terminus"}
                               :eastbound_terminus -> {"eastbound-terminus", "stop-bubble-terminus"}
                             end
    content_tag(:div, class: "stop-bubble green-line-bubble #{div_class}") do
      content_tag :svg, viewBox: "0 0 42 42", class: "icon icon-green-branch-bubble #{svg_class}" do
        [
          content_tag(:circle, "", r: 20, cx: 20, cy: 20, transform: "translate(2,2)"),
          content_tag(:text, branch, font_size: 24, x: 14, y: 30)
        ]
      end
    end
  end

  @spec zone(map | nil, Stops.Stop.t) :: Phoenix.HTML.Safe.t
  defp zone(nil, _stop), do: ""
  defp zone(zones, stop) do
    content_tag :div, class: "zone" do
      ["Zone "<>zones[stop.id]]
    end
  end

  @doc """
  Whether or not to show the line as a solid line or a dashed/collapsed line.
  """
  @spec display_collapsed?(
    String.t | nil,
    String.t,
    {:expand, String.t, String.t} | Stops.Stop.t,
    atom,
    String.t | nil,
    GreenLine.stop_routes_pair) :: boolean
  def display_collapsed?(expanded, route_for_line, next, line_status, branch_to_expand, stops_on_routes) do
    cond do
      line_status == :line -> true
      route_for_line == branch_to_expand && branch_to_expand != expanded -> true
      match?({:expand, _, ^expanded}, next) -> false
      match?({:expand, _, _}, next) -> true
      !GreenLine.stop_on_route?(next.id, route_for_line, stops_on_routes) -> true
      true -> false
    end
  end
end
