defmodule Site.Components.Buttons.ModeButtonList do
  @moduledoc """

  Renders a ButtonGroup with alert icons and subway icons for subway routes. Optionally adds a
  "view all" link to the bus route list.

  """
  alias Site.Components.Icons.{SvgIcon, SvgIconWithCircle}
  alias Site.Components.Buttons.ButtonGroup
  import Phoenix.HTML

  defstruct class:     "",
            id:        nil,
            conn:      Site.Endpoint,  # not a conn, but works in the link helpers
            routes:    [
              %Routes.Route{id: "CR-Fitchburg", key_route?: false, name: "Fitchburg Line", type: 2},
              %Routes.Route{id: "CR-Worcester", key_route?: false, name: "Framingham/Worcester Line", type: 2}
            ],
            route_type: :commuter_rail,
            alerts:    [],
            date: nil,
            truncated_list?: false

  @type t :: %__MODULE__{
    class: String.t,
    id: String.t | nil,
    conn: Plug.Conn.t,
    routes: [Routes.Route.t | ButtonGroup.button_arguments],
    alerts: [Alerts.Alert.t] | nil,
    date: DateTime.t | nil,
    truncated_list?: boolean
  }

  @doc """
  Returns a string with the classs to be applied to the button group container. The classes include:
  1. `mode-button-group` (always present)
  2. the route type, with underscores replaced by hyphens so they play nice with Pronto (always present)
  3. Any classes passed through in the arguments
  4. `truncated` if `args.include_all_link == true`
  """
  @spec list_class(__MODULE__.t) :: String.t
  def list_class(args) do
    args.route_type
    |> Atom.to_string
    |> String.replace("_", "-")
    |> Kernel.<>(" mode-button-group")
    |> add_truncate_class(args.truncated_list?)
  end

  @spec add_truncate_class(String.t, boolean) :: String.t
  defp add_truncate_class(class, true), do: "#{class} truncated"
  defp add_truncate_class(class, false), do: class

  @doc """
  Returns a list of tuples representing the content to be rendered inside of a button. If any mode will always have
  the same content regardless of circumstances (such as The RIDE), that mode's routes can be provided as a list
  of {link_text, href} tuples instead of needing to use a %Route{} struct.
  """
  @spec make_buttons(__MODULE__.t) :: [ButtonGroup.button_arguments]
  def make_buttons(%__MODULE__{routes: [{text, link}]}) when is_binary(text) and is_binary(link), do: [{text, link}]
  def make_buttons(args) do
    Enum.map(args.routes, &button_content(&1, args)) ++ maybe_add_view_all(args)
  end

  @doc """
  Returns a tuple that contains:
  1. A list of elements to be rendered inside of each button:
    - a subway icon if route type is subway,
    - Route name
    - an alert icon if the route has an alert
  2. The url that the link should point to.
  """
  @spec button_content(Routes.Route.t, __MODULE__.t) :: {[String.t | Phoenix.HTML.Safe.t], String.t}
  def button_content(route, %__MODULE__{conn: conn, alerts: alerts, date: date}) do
    {[
      icon_if_subway(route),
      Phoenix.HTML.Tag.content_tag(:span, [Site.ViewHelpers.clean_route_name(route.name), alert_icon(route, alerts, date)], class: "mode-button-text")
    ], Site.Router.Helpers.schedule_path(conn, :show, route.id)}
  end

  @doc """
  Returns a subway icon for subway lines, and an empty string for any other mode.
  """
  @spec icon_if_subway(Routes.Route.t) :: String.t | Phoenix.HTML.Safe.t
  def icon_if_subway(%Routes.Route{type: route_type, id: route_id}) when route_type in [0,1] do
    Site.PageView.svg_icon_with_circle(%SvgIconWithCircle{
      icon: "#{route_id}_line" |> String.downcase |> String.to_existing_atom,
      class: "icon-small"
    })
  end
  def icon_if_subway(_), do: ""

  # Returns an alert icon if the route has an alert.
  @spec alert_icon(Routes.Route.t, [Alerts.Alert.t], DateTime.t) :: Phoenix.HTML.Safe.t
  defp alert_icon(route, alerts, date) do
    route
    |> has_alert?(alerts, date)
    |> do_alert_icon
  end

  # Returns true if there is a non-notice alert for the given route on `date`
  defp has_alert?(route, alerts, date) do
    date = date || Util.now()
    entity = %Alerts.InformedEntity{route_type: route.type, route: route.id}
    Enum.any?(alerts, fn alert -> not Alerts.Alert.is_notice?(alert, date) &&
                                  Alerts.Match.match([alert], entity, date) == [alert]
                      end)
  end

  @spec do_alert_icon(Alerts.Alert.t) :: Phoenix.HTML.Safe.t | String.t
  defp do_alert_icon(false), do: ""
  defp do_alert_icon(true), do: Site.PageView.svg_icon(%SvgIcon{icon: :alert, class: "icon-small"})

  @spec mode_breakpoint_widths(atom) :: map
  def mode_breakpoint_widths(:subway), do: %{xs: 6, md: 3, xxl: 3}
  def mode_breakpoint_widths(:commuter_rail), do: %{xs: 6, sm: 6, md: 4, lg: 3}
  def mode_breakpoint_widths(:bus), do: %{xs: 4, sm: 4, md: 2, xxl: 2}
  def mode_breakpoint_widths(:ferry), do: %{xs: 12, sm: 4, md: 4, xxl: 4}
  def mode_breakpoint_widths(:the_ride), do: %{xs: 12, md: 6, xxl: 3}

  @doc """
  Returns a link to view all routes if `include_all_link == true`. Currently only implemented for buses.
  """
  @spec maybe_add_view_all(__MODULE__.t) :: [ButtonGroup.button_arguments]
  def maybe_add_view_all(%{route_type: :bus, truncated_list?: true}) do
    [{[
      "View all ",
      Phoenix.HTML.Tag.content_tag(:span, [class: "no-wrap"], do: [
        "buses ",
        Phoenix.HTML.Tag.content_tag(:i, "", class: "fa fa-arrow-right")
      ])
    ], Site.Router.Helpers.mode_path(Site.Endpoint, :bus)}]
  end
  def maybe_add_view_all(_), do: []
end
