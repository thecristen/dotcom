defmodule Site.Plugs.Alerts do
  @moduledoc """

  Assigns some variables to the conn for relevant alerts:

  * all_alerts: any alert, regardless of time, that matches a query parameter
  * current_alerts: currently valid alerts/notices (current based on date parameter)
  * upcoming alerts: alerts/notices that will be valid some other time
  * alerts: current valid alerts
  * notices: currently valid notices, followed by upcoming alerts
  """
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(conn, []) do
    conn
    |> assign_all_alerts
    |> assign_current_upcoming
    |> assign_alerts_notices
  end

  defp assign_all_alerts(conn) do
    conn
    |> assign(:all_alerts, alerts(conn))
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
    |> assign(:current_alerts, current_alerts |> sort)
    |> assign(:upcoming_alerts, upcoming_alerts |> sort)
  end

  defp assign_alerts_notices(%{assigns: %{
                                  date: date,
                                  current_alerts: current_alerts,
                                  upcoming_alerts: upcoming_alerts
                               }} = conn) do
    {notices, alerts} = current_alerts
    |> Enum.partition(fn alert -> Alerts.Alert.is_notice?(alert, date) end)

    # put anything upcoming in the notices block, but at the end
    notices = [notices, upcoming_alerts]
    |> Enum.concat
    |> Enum.uniq

    conn
    |> assign(:notices, notices |> sort)
    |> assign(:alerts, alerts |> sort)
  end

  defp alerts(%{assigns: %{all_alerts: all_alerts}}) when is_list(all_alerts) do
    # if the conn already has alerts from somewhere, use them.
    all_alerts
  end
  defp alerts(%{params: params, assigns: %{route: route}}) when route != nil do
    params = put_in params["route_type"], route.type

    alerts_from_params(params)
  end
  defp alerts(%{params: params}) do
    alerts_from_params(params)
  end

  defp alerts_from_params(params) do
    base_entity = %Alerts.InformedEntity{
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

    Alerts.Repo.all
    |> Alerts.Match.match(entities)
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
    alerts
    |> Enum.sort_by(&{-Timex.to_unix(&1.updated_at), &1.id})
  end
end
