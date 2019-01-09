defmodule SiteWeb.AlertView do
  use SiteWeb, :view
  alias Alerts.Alert
  alias Routes.Route
  alias SiteWeb.PartialView.SvgIconWithCircle
  alias Stops.Stop
  import SiteWeb.ViewHelpers
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import SiteWeb.PartialView.SvgIconWithCircle, only: [svg_icon_with_circle: 1]

  @doc """

  Used to render a group of alerts.

  """
  def group(opts) do
    route = Keyword.fetch!(opts, :route)
    stop? = Keyword.get(opts, :stop?, false)
    show_empty? = Keyword.get(opts, :show_empty?, false)
    priority_filter = Keyword.get(opts, :priority_filter, :any)

    alerts =
      opts
      |> Keyword.fetch!(:alerts)
      |> Enum.filter(&filter_by_priority(priority_filter, &1))

    case {alerts, show_empty?} do
      {[], true} ->
        location = if stop?, do: ["at ", route.name], else: ["on the ", route.name]

        content_tag(
          :div,
          ["Service is running as expected ", location, ". There are no alerts at this time."],
          class: "callout"
        )

      {[], false} ->
        ""

      _ ->
        render(__MODULE__, "group.html", alerts: alerts, route: route)
    end
  end

  @spec filter_by_priority(boolean, Alert.t()) :: boolean
  defp filter_by_priority(:any, _), do: true

  defp filter_by_priority(priority_filter, %{priority: priority})
       when priority_filter == priority,
       do: true

  defp filter_by_priority(_, _), do: false

  @doc """

  Renders an inline list of alerts, passed in as the alerts key.

  """
  def inline(_conn, [{:alerts, []} | _]) do
    ""
  end

  def inline(_conn, [{:alerts, nil} | _]) do
    ""
  end

  def inline(_conn, assigns) do
    case Keyword.get(assigns, :time) do
      value when not is_nil(value) ->
        render(__MODULE__, "inline.html", assigns)
    end
  end

  @doc """
  """
  def alert_effects(alerts, upcoming_count)
  def alert_effects([], 0), do: "There are no alerts for today."
  def alert_effects([], 1), do: "There are no alerts for today; 1 upcoming alert."

  def alert_effects([], count),
    do: ["There are no alerts for today; ", count |> Integer.to_string(), " upcoming alerts."]

  def alert_effects([alert], _) do
    {Alert.human_effect(alert), ""}
  end

  def alert_effects([alert | rest], _) do
    {Alert.human_effect(alert), ["+", rest |> length |> Integer.to_string(), " more"]}
  end

  def effect_name(%{lifecycle: lifecycle} = alert)
      when lifecycle in [:new, :unknown] do
    Alert.human_effect(alert)
  end

  def effect_name(alert) do
    Alert.human_effect(alert)
  end

  defp alert_label_class(badge) do
    ["u-small-caps", "m-alert-item__badge"]
    |> do_alert_label_class(badge)
    |> Enum.join(" ")
  end

  defp do_alert_label_class(class_list, "Upcoming") do
    ["m-alert-item__badge--upcoming" | class_list]
  end

  defp do_alert_label_class(class_list, _) do
    class_list
  end

  def alert_updated(alert, relative_to) do
    date =
      if Timex.equal?(relative_to, alert.updated_at) do
        "Today at"
      else
        Timex.format!(alert.updated_at, "{M}/{D}/{YYYY}")
      end

    time = format_schedule_time(alert.updated_at)

    ["Last Updated: ", date, 32, time]
  end

  def format_alert_description(text) do
    import Phoenix.HTML

    text
    |> html_escape
    |> safe_to_string
    # an initial header
    |> String.replace(~r/^(.*:)\s/, "<strong>\\1</strong>\n")
    # all other start with a line break
    |> String.replace(~r/\n(.*:)\s/, "<br /><strong>\\1</strong>\n")
    |> String.replace(~r/\s*\n/s, "<br />")
    |> replace_urls_with_links
  end

  @url_regex ~r/(https?:\/\/)?([\da-z\.-]+)\.([a-z]{2,6})([\/\w\.-]*)*\/?/i

  @spec replace_urls_with_links(String.t()) :: Phoenix.HTML.safe()
  def replace_urls_with_links(text) do
    @url_regex
    |> Regex.replace(text, &create_url/1)
    |> raw
  end

  defp create_url(url) do
    # I could probably convince the Regex to match an internal period but not
    # one at the end, but this is clearer. -ps
    {url, suffix} =
      if String.ends_with?(url, ".") do
        String.split_at(url, -1)
      else
        {url, ""}
      end

    full_url = ensure_scheme(url)
    ~s(<a target="_blank" href="#{full_url}">#{url}</a>#{suffix})
  end

  defp ensure_scheme("http://" <> _ = url), do: url
  defp ensure_scheme("https://" <> _ = url), do: url
  defp ensure_scheme(url), do: "http://" <> url

  @spec group_header_path(Route.t() | Stop.t()) :: String.t()
  def group_header_path(%Route{id: route_id}) do
    schedule_path(SiteWeb.Endpoint, :show, route_id)
  end

  def group_header_path(%Stop{id: stop_id}) do
    stop_path(SiteWeb.Endpoint, :show, stop_id)
  end

  @spec group_header_name(Route.t() | Stop.t()) :: Phoenix.HTML.Safe.t()
  defp group_header_name(%Route{long_name: long_name, name: name, type: 3}) do
    [name, content_tag(:span, long_name, class: "h3 m-alerts-header__long-name")]
  end

  defp group_header_name(%Route{name: name}) do
    [name]
  end

  defp group_header_name(%Stops.Stop{name: name}) do
    [name]
  end

  @spec show_mode_icon?(Route.t() | Stop.t()) :: boolean
  defp show_mode_icon?(%Stop{}), do: false

  defp show_mode_icon?(%Route{}), do: true

  @spec route_icon(Route.t()) :: Phoenix.HTML.Safe.t()
  def route_icon(%Route{type: 3, description: :rapid_transit}) do
    svg_icon_with_circle(%SvgIconWithCircle{icon: :silver_line, aria_hidden?: true})
  end

  def route_icon(%Route{} = route) do
    svg_icon_with_circle(%SvgIconWithCircle{icon: Route.icon_atom(route), aria_hidden?: true})
  end

  @spec mode_buttons(atom) :: [Phoenix.HTML.Safe.t()]
  def mode_buttons(selected) do
    for mode <- [:subway, :bus, :commuter_rail, :ferry, :access] do
      link(
        [
          content_tag(
            :div,
            [
              content_tag(:div, type_icon(mode), class: "m-alerts__mode-icon"),
              content_tag(:div, type_name(mode), class: "m-alerts__mode-name")
            ],
            class: [
              "m-alerts__mode-button",
              if mode == selected do
                [" ", "m-alerts__mode-button--selected"]
              else
                []
              end
            ]
          )
        ],
        to: alert_path(SiteWeb.Endpoint, :show, mode),
        class: "m-alerts__mode-button-container"
      )
    end
  end

  @spec type_name(atom) :: String.t()
  defp type_name(:commuter_rail), do: "Rail"
  defp type_name(mode), do: mode_name(mode)

  @spec type_icon(atom) :: Phoenix.HTML.Safe.t()
  defp type_icon(:access), do: svg("icon-accessible-default.svg")
  defp type_icon(mode), do: mode_icon(mode, :default)

  @spec alert_icon(Alert.icon_type()) :: Phoenix.HTML.Safe.t()
  defp alert_icon(:shuttle), do: svg("icon-shuttle-default.svg")
  defp alert_icon(:cancel), do: svg("icon-cancelled-default.svg")
  defp alert_icon(:snow), do: svg("icon-snow-default.svg")
  defp alert_icon(:alert), do: svg("icon-alerts-triangle.svg")
  defp alert_icon(:none), do: ""

  @spec empty_message_for_timeframe(String.t() | nil) :: String.t()
  def empty_message_for_timeframe("current"), do: "There are no current alerts."

  def empty_message_for_timeframe("upcoming"),
    do: "There are no planned service alerts at this time."

  def empty_message_for_timeframe(_), do: "There are no alerts at this time."
end
