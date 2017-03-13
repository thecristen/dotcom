defmodule Site.Plugs.AlertsTest do
  use ExUnit.Case, async: true
  use ExCheck

  alias Alerts.{Alert, InformedEntity}
  alias Site.Plugs.Alerts
  import Plug.Conn, only: [assign: 3, fetch_query_params: 1]

  setup _ do
    conn = Phoenix.ConnTest.build_conn
    {:ok, %{conn: conn}}
  end

  test "assigns alerts, upcoming_alerts", %{conn: conn} do
    conn = conn
    |> assign(:date, Util.service_date())
    |> Alerts.call(alerts_fn: fn -> [] end)

    assert conn.assigns.all_alerts == []
    assert conn.assigns.upcoming_alerts == []
    assert conn.assigns.alerts == []
  end

  test "includes alerts which only match the route type", %{conn: conn} do
    route = %Routes.Route{
      type: 2
    }
    cr_alert = %Alert{
      informed_entity: [%InformedEntity{route_type: 2}],
      active_period: [{nil, nil}],
      updated_at: Util.now
    }
    ferry_alert = %Alert{
      informed_entity: [%InformedEntity{route_type: 4}],
      active_period: [{nil, nil}],
      updated_at: Util.now
    }

    conn = conn
    |> assign(:date, Util.today)
    |> assign(:route, route)
    |> fetch_query_params
    |> Alerts.call(alerts_fn: fn -> [cr_alert, ferry_alert] end)

    assert conn.assigns.all_alerts == [cr_alert]
  end

  test "filters by direction ID if it is assigned without a query param", %{conn: conn} do
    date_time = ~N[2017-02-22 12:00:00]
    alerts = [
      %Alert{
        informed_entity: [%InformedEntity{direction_id: 1}],
        active_period: [{nil, nil}],
        updated_at: date_time
      },
      %Alert{
        informed_entity: [%InformedEntity{direction_id: 0}],
        active_period: [{nil, nil}],
        updated_at: date_time
      }
    ]

    conn = conn
    |> assign(:route, %Routes.Route{type: 1})
    |> assign(:date, Timex.to_date(date_time))
    |> assign(:direction_id, 1)
    |> fetch_query_params
    |> Alerts.call(alerts_fn: fn -> alerts end)

    assert conn.assigns.all_alerts == [hd(alerts)]
  end
end
