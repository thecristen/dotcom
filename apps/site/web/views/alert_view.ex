defmodule Site.AlertView do
  use Site.Web, :view

  @doc """
  Takes a list of alerts and returns a string summarizing their effects, such as "3 Delays, Stop
  Closure, 4 Station Issues". Adds an optional suffix if the list of alerts is non-empty.
  """
  def display_alert_effects(alerts)
  def display_alert_effects([]), do: ""
  def display_alert_effects(alerts) do
    alerts
    |> Enum.group_by(&(&1.effect_name))
    |> Enum.map(fn {effect_name, alerts} ->
      num_alerts = length(alerts)
      if num_alerts > 1 do
        "#{num_alerts} #{Inflex.inflect(effect_name, num_alerts)}"
      else
        effect_name
      end
    end)
    |> Enum.join(", ")
  end

  def display_alert_updated(alert) do
    {:ok, formatted} = alert.updated_at
    |> Timex.Format.DateTime.Formatters.Relative.relative_to(Util.now, "{relative}")

    "Updated #{formatted}"
  end

  def newline_to_br(text) do
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
