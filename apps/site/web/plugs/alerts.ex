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

  defp assign_current_upcoming(%{assigns: %{all_alerts: all_alerts}} = conn) do
    date = date(conn.params["date"])

    {current_alerts, not_current_alerts} = all_alerts
    |> Enum.partition(fn alert -> Alerts.Match.any_time_match?(alert, date) end)

    upcoming_alerts = not_current_alerts
    |> Enum.filter(fn alert ->
      Enum.any?(alert.active_period, fn {start, _} ->
        Timex.before?(date, start)
      end)
    end)

    conn
    |> assign(:current_alerts, current_alerts)
    |> assign(:upcoming_alerts, upcoming_alerts)
  end

  defp assign_alerts_notices(%{assigns: %{
                                  current_alerts: current_alerts,
                                  upcoming_alerts: upcoming_alerts
                               }} = conn) do
    {notices, alerts} = current_alerts
    |> Enum.partition(&Alerts.Alert.is_notice?/1)

    # put anything upcoming in the notices block, but at the end
    notices = [notices, upcoming_alerts]
    |> Enum.concat
    |> Enum.uniq

    conn
    |> assign(:notices, notices)
    |> assign(:alerts, alerts)
  end

  defp alerts(%{params: params, assigns: %{route: route}}) when route != nil do
    params = put_in params["route_type"], route.type

    alerts_from_params(params)
  end
  defp alerts(%{params: params}) do
    alerts_from_params(params)
  end

  defp alerts_from_params(params) do
    base_entity = struct(Alerts.InformedEntity, [
          route_type: params["route_type"],
          route: params["route"],
          trip: params["trip"],
          direction_id: direction_id(params["direction_id"])
        ])

    entities = [params["origin"], params["dest"]]
    |> Enum.uniq
    |> Enum.map(fn stop -> %{base_entity | stop: stop} end)

    Alerts.Repo.all
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

  defp date(nil) do
    Util.now
  end
  defp date(str) when is_binary(str) do
    case Timex.parse(str, "{ISOdate}") do
      {:ok, value} -> Timex.to_date(value)
      _ -> Util.today
    end
  end

  defp sort(alerts) do
    alerts
    |> Enum.sort_by(&(- Timex.to_unix(&1.updated_at)))
  end
end
