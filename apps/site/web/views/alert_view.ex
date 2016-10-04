defmodule Site.AlertView do
  use Site.Web, :view
  alias Routes.Route

  @doc """

  Used by the schedule view to render a link/modal with relevant alerts.

  """
  def modal(%{assigns: %{alerts: alerts} = assigns} = conn) when alerts != [] do
    route = assigns.route

    render(__MODULE__, "modal.html", alerts: alerts, route: route)
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

  Renders a small icon along with a message

  """
  def tooltip() do
    render(__MODULE__, "tooltip.html", %{})
  end

  @doc """
  """
  def display_alert_effects(alerts)
  def display_alert_effects([]), do: {"", ""}
  def display_alert_effects([alert]) do
    {alert.effect_name, ""}
  end
  def display_alert_effects([alert|rest]) do
    {alert.effect_name, "+#{length rest} more"}
  end

  def display_alert_updated(alert) do
    display_alert_updated(alert, Util.today)
  end
  def display_alert_updated(alert, relative_to) do
    date = if Timex.equal?(relative_to, alert.updated_at) do
      "Today at"
    else
      Timex.format!(alert.updated_at, "{M}/{D}/{YYYY}")
    end
    time = Timex.format!(alert.updated_at, "{h12}:{m} {AM}")

    "Last Updated: #{date} #{time}"
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
end
