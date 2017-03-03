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
        link(stop.name, to: stop_path(conn, :show, stop.id)),
        zone(conn.assigns[:zones], stop),
        content_tag(:div, [class: "route-icons"], do: Enum.map(stop_features, &svg_icon_with_circle(%SvgIconWithCircle{icon: &1})))
      ]
    end
  end

  @spec zone(map | nil, Stop.Stop.t) :: Phoenix::HTML.Safe.t
  defp zone(nil, _stop), do: ""
  defp zone(zones, stop) do
    content_tag :span, class: "pull-right" do
      ["Zone "<>zones[stop.id]]
    end
  end
end
