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

    case {alerts, upcoming_alerts} do
      {[], []} -> ""
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
  def alert_effects(alerts, upcoming_count)
  def alert_effects([], 0), do: "There are no alerts for today."
  def alert_effects([], 1), do: "There are no alerts for today; 1 upcoming alert."
  def alert_effects([], count), do: "There are no alerts for today; #{count} upcoming alerts."
  def alert_effects([alert], _) do
    {effect_name(alert),
     ""}
  end
  def alert_effects([alert|rest], _) do
    {effect_name(alert),
     "+#{length rest} more"}
  end

  def effect_name(%{effect_name: name, lifecycle: "New"}) do
    name
  end
  def effect_name(%{effect_name: name, lifecycle: lifecycle}) do
    "#{name} (#{lifecycle})"
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
