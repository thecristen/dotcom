defmodule Site.Plugs.Alerts do
  @moduledoc """
  Assigns some variables to the conn for relevant alerts:

  * all_alerts: any alert, regardless of time, that matches a query parameter
  * alerts: currently valid alerts/notices (current based on date parameter)
  * upcoming alerts: alerts/notices that will be valid some other time
  """
  import Plug.Conn, only: [assign: 3]

  @default_opts [
    alerts_fn: &Alerts.Repo.all/0
  ]

  def init(opts) do
    Keyword.merge(@default_opts, opts)
  end

  # can pass in a different function to use for getting all the alerts
  def call(conn, opts) do
    conn
    |> assign_all_alerts(Keyword.get(opts, :alerts_fn))
    |> assign_current_upcoming
  end

  defp assign_all_alerts(conn, alert_fn) do
    conn
    |> assign(:all_alerts, alerts(conn, alert_fn))
  end

  defp assign_current_upcoming(%{assigns: %{all_alerts: all_alerts, date: date}} = conn) do
    {current_alerts, not_current_alerts} = all_alerts
    |> Enum.partition(fn alert -> Alerts.Match.any_time_match?(alert, date) end)

    upcoming_alerts = not_current_alerts
    |> Enum.filter(fn alert ->
      Enum.any?(alert.active_period, fn
        {nil, nil} ->
          true
        {nil, stop} ->
          not Timex.before?(date, stop)
        {start, _} ->
          Timex.before?(date, start)
      end)
    end)

    conn
    |> assign(:alerts, current_alerts)
    |> assign(:upcoming_alerts, upcoming_alerts)
  end

  defp alerts(%{assigns: %{all_alerts: all_alerts}}, _) when is_list(all_alerts) do
    # if the conn already has alerts from somewhere, use them.
    all_alerts
  end
  defp alerts(%{params: params, assigns: %{route: route}}, alert_fn) when route != nil do
    params = put_in params["route_type"], route.type

    alerts_from_params(params, alert_fn)
  end
  defp alerts(_, alert_fn) do
    alert_fn.()
    |> sort
  end

  defp alerts_from_params(params, alert_fn) do
    base_entity = %Alerts.InformedEntity{
      route_type: params["route_type"],
      route: params["route"],
      direction_id: direction_id(params["direction_id"])
    }

    entities = [params["origin"], params["dest"]]
    |> Enum.uniq
    |> Enum.map(fn stop -> %{base_entity | stop: stop} end)

    entities = [nil, params["trip"]]
    |> Enum.uniq
    |> Enum.flat_map(fn trip ->
      Enum.map(entities, fn entity ->
        %{entity | trip: trip}
      end)
    end)

    alert_fn.()
    |> Alerts.Match.match(entities)
    |> sort
  end

  defp direction_id(nil) do
    nil
  end
  defp direction_id(str) when is_binary(str) do
    case Integer.parse(str) do
      {id, ""} -> id
      _ -> nil
    end
  end

  defp sort(alerts) do
    Alerts.Sort.sort(alerts)
  end
end
