defmodule Site.ScheduleView do
  use Site.Web, :view

  def update_url(%{params: params} = conn, query) do
    query_map = query
    |> Enum.map(fn {key, value} -> {Atom.to_string(key), to_string(value)} end)
    |> Enum.into(%{})

    new_query = params
    |> Map.merge(query_map)
    |> Enum.into([])
    |> Enum.reject(&empty_value?/1)

    schedule_path(conn, :index, new_query)
  end

  @doc """
  Puts the conn into the assigns dictionary so that downstream templates can use it
  """
  def forward_assigns(%{assigns: assigns}=conn) do
    assigns
    |> Dict.put(:conn, conn)
  end

  def has_alerts?(alerts, schedule) do
    entity = %Alerts.InformedEntity{
      route_type: schedule.route.type,
      route: schedule.route.id,
      stop: schedule.stop.id
    }

    # hack to unmatch the "Fares go up on July 1" alert on everything
    matched = alerts
    |> Alerts.Match.match(entity, schedule.time)
    |> Enum.reject(fn alert ->
      %Alerts.InformedEntity{route_type: schedule.route.type} in alert.informed_entity
    end)

    matched != []
  end

  @doc """
  Partition a enum of alerts into a pair of those that should be displayed as alerts, and those
  that should be displayed as notices.
  """
  def alerts_and_notices(alerts) do
    Enum.partition(alerts, &display_as_alert?/1)
  end

  defp display_as_alert?(alert) do
    # The list of effects which should be shown as an alert -- others
    # are shown with less emphasis in the UI
    alert_effects = [
      "Delay", "Shuttle", "Stop Closure", "Snow Route", "Cancellation", "Detour", "No Service"
    ]
    alert.effect_name in alert_effects
  end

  def display_alert_effects([], _), do: ""
  def display_alert_effects(alerts, suffix) do
    alerts
    |> Enum.map(&(&1.effect_name))
    |> Enum.uniq
    |> Enum.join(", ")
    |> Kernel.<>(suffix)
  end

  def hidden_query_params(conn, opts \\ []) do
    exclude = Keyword.get(opts, :exclude, [])
    conn.params
    |> Enum.reject(fn {key, _} -> key in exclude end)
    |> Enum.map(&hidden_tag/1)
  end

  defp empty_value?({_, value}) do
    value in ["", nil]
  end

  defp hidden_tag({key, value}) do
    tag :input, type: "hidden", name: key, value: value
  end

end
