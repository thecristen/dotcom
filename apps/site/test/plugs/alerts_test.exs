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
    |> Alerts.call(fn -> [] end)

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
    |> Alerts.call(fn -> [cr_alert, ferry_alert] end)

    assert conn.assigns.all_alerts == [cr_alert]
  end

  property "sorts the notices by their updated at times (newest to oldest)", %{conn: conn} do
    date = Util.service_date() |> Timex.shift(days: 1) # put them in the future
    for_all times in list(pos_integer()) do
      # create alerts with a bunch of updated_at times
      alerts = for time <- times do
        dt = date |> Timex.shift(seconds: time)
        %Alert{id: inspect(make_ref()),
               updated_at: dt,
               active_period: [{nil, nil}]}
      end

      conn = conn
      |> assign(:date, date)
      |> Alerts.call(fn -> alerts end)

      sorted = alerts
      |> Enum.sort_by(&(&1.id))
      |> Enum.reverse # reverse after ID sort so that the second reverse puts
                      # them in the right order
      |> Enum.sort_by(&(&1.updated_at))
      |> Enum.reverse

      assert conn.assigns.all_alerts == sorted
      assert conn.assigns.alerts == sorted
    end
  end
end
