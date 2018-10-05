defmodule SiteWeb.ModeView do
  use SiteWeb, :view
  alias SiteWeb.PartialView.SvgIconWithCircle
  alias Routes.Route

  def get_route_group(:commuter_rail = route_type, route_groups) do
    # Note that we do not sort the commuter rail routes by name as we
    # want to preserve the order supplied by the API, keeping Foxboro
    # last.
    route_groups[route_type]
  end
  def get_route_group(:the_ride, _) do
    [{"MBTA Paratransit Program", cms_static_page_path(SiteWeb.Endpoint, "/accessibility/the-ride")}]
  end
  def get_route_group(route_type, route_groups), do: route_groups[route_type]

  @spec fares_note(String) :: Phoenix.HTML.safe | String.t
  @doc "Returns a note describing fares for the given mode"
  def fares_note("Commuter Rail") do
    content_tag :p do
      ["Fares for the Commuter Rail are separated into zones that depend on your origin and destination. Find your fare cost by entering your origin and destination
      or view ",
      link("table of fare zones.", to: cms_static_page_path(SiteWeb.Endpoint, "/fares/commuter-rail-fares/zones"))]
    end
  end
  def fares_note(_mode) do
      ""
  end

  @doc """
  Builds the header tag for a mode group. Adds a "view all" link for bus.
  """
  @spec mode_group_header(atom, String.t, boolean) :: Phoenix.HTML.Safe.t
  def mode_group_header(mode, href, is_homepage?) do
    is_homepage?
    |> mode_group_header_tag()
    |> content_tag(mode_group_header_content(mode, href), class: "m-mode__header")
  end

  @spec mode_group_header_tag(boolean) :: :h2 | :h3
  defp mode_group_header_tag(is_homepage?)
  defp mode_group_header_tag(true), do: :h3
  defp mode_group_header_tag(false), do: :h2

  @spec mode_group_header_content(atom, String.t) :: [Phoenix.HTML.Safe.t]
  defp mode_group_header_content(mode, href) do
    [
      link([
        svg_icon_with_circle(%SvgIconWithCircle{icon: mode, aria_hidden?: true}),
        " ",
        Routes.Route.type_name(mode)
      ], to: href, class: "m-mode__name"),
      view_all_link(mode, href)
    ]
  end

  @spec view_all_link(atom, String.t) :: [Phoenix.HTML.Safe.t]
  defp view_all_link(:bus, href) do
    [
      link("View all bus routes", to: href, class: "c-call-to-action m-mode__view-all")
    ]
  end
  defp view_all_link(_, _) do
    []
  end

  @spec grid_button_path(atom, Plug.Conn.t) :: String.t
  def grid_button_path(:the_ride, %Plug.Conn{} = conn) do
    cms_static_page_path(conn, "/accessibility/the-ride")
  end
  def grid_button_path(%Route{} = route, %Plug.Conn{} = conn) do
    schedule_path(conn, :show, route)
  end

  @doc """
  Returns the value to add as a modifier for the .c-grid-button class.
  """
  @spec grid_button_class_modifier(atom | Route.t) :: String.t
  def grid_button_class_modifier(:the_ride) do
    "the-ride"
  end
  def grid_button_class_modifier(%Route{} = route) do
    route_to_class(route)
  end

  @doc """
  Used to determine if the mode icon should be rendered on a mode button.
  The Ride icon is never shown. Subway icons are always rendered.
  Other modes rely on the :show_icon? boolean assign.
  """
  @spec show_icon?(atom | Route.t, boolean) :: boolean
  def show_icon?(:the_ride, _) do
    false
  end
  def show_icon?(%Route{type: type}, _) when type in [0, 1] do
    true
  end
  def show_icon?(_, bool) when bool in [true, false] do
    bool
  end

  @spec grid_button_text(atom | Route.t) :: String.t
  def grid_button_text(:the_ride) do
    "MBTA Paratransit Program"
  end
  def grid_button_text(%Route{name: name}) do
    break_text_at_slash(name)
  end

  # Returns true if there is a non-notice alert for the given route on `date`
  @spec has_alert?(Route.t | :the_ride, [Alerts.Alert.t], DateTime.t | nil) :: boolean
  def has_alert?(:the_ride, _, _) do
    false
  end
  def has_alert?(%Route{} = route, alerts, date) do
    date = date || Util.now()
    entity = %Alerts.InformedEntity{route_type: route.type, route: route.id}
    Enum.any?(alerts, fn alert -> not Alerts.Alert.is_notice?(alert, date) &&
                                  Alerts.Match.match([alert], entity, date) == [alert]
                      end)
  end
end
