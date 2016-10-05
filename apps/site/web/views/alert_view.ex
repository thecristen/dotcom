defmodule Site.AlertView do
  use Site.Web, :view

  @doc """

  Used by the schedule view to render a link/modal with relevant alerts.

  """
  def modal(opts) do
    alerts = Keyword.fetch!(opts, :alerts)
    _ = Keyword.fetch!(opts, :route)

    upcoming_alerts = opts[:upcoming_alerts] || []

    opts = opts
    |> Keyword.put(:upcoming_alert_count, length(upcoming_alerts))

    case alerts do
      [] -> ""
      _ ->
        render(__MODULE__, "modal.html", opts)
    end
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
  def alert_effects(alerts)
  def alert_effects([]), do: "No alerts for today."
  def alert_effects([alert]) do
    {"#{alert.effect_name} (#{alert.lifecycle})",
     ""}
  end
  def alert_effects([alert|rest]) do
    {"#{alert.effect_name} (#{alert.lifecycle})",
     "+#{length rest} more"}
  end

  def alert_updated(alert) do
    alert_updated(alert, Util.today)
  end
  def alert_updated(alert, relative_to) do
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
