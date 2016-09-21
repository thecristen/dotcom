defmodule Site.AlertView do
  use Site.Web, :view
  alias Routes.Route

  @doc """

  Used by the schedule view to render a link/modal with relevant alerts.

  """
  def modal(%{assigns: %{notices: notices, alerts: alerts} = assigns} = conn) when notices != [] or alerts != [] do
    assigns = assigns
    |> Map.put(:layout, false)
    |> Map.put(:conn, conn)

    case {Route.type_atom(conn.assigns.route), length(notices)} do
      {:bus, 0} -> nil
      {_, _} -> render(__MODULE__, "modal.html", assigns)
    end
  end
  def modal(_conn) do
    ""
  end

  @doc """

  Renders an inline list of alerts, passed in as the alerts key.

  """
  def inline(_conn, [{:alerts, []}|_]) do
    ""
  end
  def inline(_conn, [{:alerts, nil}|_]) do
    ""
  end
  def inline(_conn, assigns) do
    case Keyword.get(assigns, :time) do
      value when not is_nil(value) ->
        render(__MODULE__, "inline.html", assigns)
    end
  end

  @doc """
  Takes a list of alerts and returns a string summarizing their effects, such as "3 Delays, Stop
  Closure, 4 Station Issues". Adds an optional suffix if the list of alerts is non-empty.
  """
  def display_alert_effects(alerts)
  def display_alert_effects([]), do: ""
  def display_alert_effects(alerts) do
    alerts
    |> Enum.group_by(&(&1.effect_name))
    |> Enum.map(&display_alert_group/1)
    |> Enum.join(", ")
  end

  defp display_alert_group({effect_name, [_]}) do
    effect_name
  end
  defp display_alert_group({effect_name, alerts}) do
    num_alerts = length(alerts)
    "#{num_alerts} #{Inflex.inflect(effect_name, num_alerts)}"
  end

  def display_alert_updated(alert) do
    {:ok, formatted} = alert.updated_at
    |> Timex.Format.DateTime.Formatters.Relative.relative_to(Util.now, "{relative}")

    "Updated #{formatted}"
  end

  def format_alert_description(text) do
    import Phoenix.HTML

    text
    |> html_escape
    |> safe_to_string
    |> String.replace(~r/^(.*:)\s/, "<strong>\\1</strong>\n") # an initial header
    |> String.replace(~r/\n(.*:)\s/, "<hr><strong>\\1</strong>\n") # all other start with an HR
    |> String.replace(~r/\s*\n/s, "<br />")
    |> raw
  end

  def get_link_background(:bus, _) do
    "bg-notice"
  end

  def get_link_background(_, []) do
    "bg-notice"
  end

  def get_link_background(_, _) do
    ""
  end

end
