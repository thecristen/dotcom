defmodule Site.ScheduleV2ControllerTest do
  use Site.ConnCase, async: true

  describe "Bus and Subway:" do
    test "all stops is assigned for a route", %{conn: conn} do
      conn = get(conn, schedule_v2_path(conn, :show, "1"))
      html_response(conn, 200)
      IO.inspect Map.keys(conn.assigns)
      assert conn.assigns.all_stops != nil
    end

    test "origin is unassigned for a route when you first view the page", %{conn: conn} do
      conn = get(conn, schedule_v2_path(conn, :show, "1"))
      html_response(conn, 200)
      assert conn.assigns.origin == nil
    end

    test "has the origin when it has been selected", %{conn: conn} do
      conn = get(conn, schedule_v2_path(conn, :show, "1", origin: "2167"))
      html_response(conn, 200)
      assert conn.assigns.origin == "2167"
    end

    test "finds a trip when origin has been selected", %{conn: conn} do
      conn = get(conn, schedule_v2_path(conn, :show, "1", origin: "2167"))
      html_response(conn, 200)
      assert conn.assigns.origin == "2167"
      assert conn.assigns.trip != nil
    end

    test "finds a trip list with origin and destination", %{conn: conn} do
      conn = get(conn, schedule_v2_path(conn, :show, "71", origin: "8178", dest: "2065"))
      html_response(conn, 200)
      assert conn.assigns.origin == "8178"
      assert conn.assigns.destination == "2065"
      assert conn.assigns.trip != nil
      assert conn.assigns.schedules != nil
      assert conn.assigns.predictions != nil
    end
  end

  describe "Subway only:" do
    test "has the full list of schedules so in order to calculate frequencys for all time blocks", %{conn: conn} do
      conn = get(conn, schedule_v2_path(conn, :frequency, "11"))
      html_response(conn, 200)
      assert conn.assigns.all_schedules != nil
    end
  end
end
