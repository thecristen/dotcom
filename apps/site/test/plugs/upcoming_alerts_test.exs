defmodule Site.Plugs.UpcomingAlertsTest do
  use ExUnit.Case, async: true
  use ExCheck

  alias Alerts.Alert
  alias Site.Plugs.UpcomingAlerts
  import Plug.Conn, only: [assign: 3]

  setup _ do
    conn = Phoenix.ConnTest.build_conn
    {:ok, %{conn: conn}}
  end

  describe "call/2" do
    @date ~D[2017-05-31]
    @date_time Timex.to_datetime(@date)
    @all_alerts [
      %Alert{id: "alert1", active_period: [{Timex.shift(@date_time, days: -1), Timex.shift(@date_time, days: 2)}]},
      %Alert{id: "alert2", active_period: [{nil, Timex.shift(@date_time, days: 5)}]},
      %Alert{id: "alert3", active_period: [{nil, nil}]},
      %Alert{id: "alert4", active_period: [{Timex.shift(@date_time, days: 2), Timex.shift(@date_time, days: 5)}]}
    ]

    test "assigns alerts, upcoming_alerts", %{conn: conn} do
      conn = conn
      |> assign(:date, @date)
      |> assign(:all_alerts, @all_alerts)
      |> UpcomingAlerts.call([])

      assert conn.assigns.alerts
      assert conn.assigns.upcoming_alerts
    end
  end
end
