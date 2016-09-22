defmodule Site.Plugs.AlertsTest do
  use ExUnit.Case, async: true
  use ExCheck

  alias Alerts.Alert
  alias Site.Plugs.Alerts
  import Phoenix.ConnTest, only: [build_conn: 0]
  import Plug.Conn, only: [assign: 3]

  test "assigns current_alerts, upcoming_alerts, alerts, notices" do
    conn = build_conn
    |> assign(:date, Timex.today)
    |> assign(:all_alerts, [])
    |> Alerts.call([])

    assert conn.assigns.current_alerts == []
    assert conn.assigns.upcoming_alerts == []
    assert conn.assigns.alerts == []
    assert conn.assigns.notices == []
  end

  property "sorts the notices by their updated at times (newest to oldest)" do
    date = Timex.today |> Timex.shift(days: 1) # put them in the future
    for_all times in list(pos_integer) do
      # create alerts with a bunch of updated_at times
      alerts = for time <- times do
        dt = date |> Timex.shift(seconds: time)
        %Alert{id: inspect(make_ref()),
               updated_at: dt,
               active_period: [{nil, nil}]}
      end

      conn = build_conn
      |> assign(:date, date)
      |> assign(:all_alerts, alerts)
      |> Alerts.call([])

      sorted = alerts
      |> Enum.sort_by(&(&1.id))
      |> Enum.reverse # reverse after ID sort so that the second reverse puts
                      # them in the right order
      |> Enum.sort_by(&(&1.updated_at))
      |> Enum.reverse

      conn.assigns.notices == sorted
    end
  end
end
