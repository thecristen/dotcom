defmodule Site.ScheduleV2ControllerTest do
  use Site.ConnCase, async: true

  describe "Bus and Subway:" do
    test "all stops is assigned for a route", %{conn: conn} do
      conn = get(conn, schedule_v2_path(conn, :show, "1"))
      html_response(conn, 200)
      assert conn.assigns.all_stops != nil
    end

    test "origin is unassigned for a route when you first view the page", %{conn: conn} do
      conn = get(conn, schedule_v2_path(conn, :show, "1"))
      html_response(conn, 200)
      assert conn.assigns.origin == nil
    end

    test "has the origin when it has been selected", %{conn: conn} do
      conn = get(conn, schedule_v2_path(conn, :show, "1", origin: "2167", direction_id: "1"))
      html_response(conn, 200)
      assert conn.assigns.origin.id == "2167"
    end

    test "finds a trip when origin has been selected", %{conn: conn} do
      conn = get(conn, schedule_v2_path(conn, :show, "1", origin: "2167", direction_id: "1"))
      html_response(conn, 200)
      assert conn.assigns.origin.id == "2167"
      assert conn.assigns.trip_info
    end

    test "finds a trip list with origin and destination", %{conn: conn} do
      conn = get(conn, schedule_v2_path(conn, :show, "1", origin: "2167", destination: "82", direction_id: "1"))
      html_response(conn, 200)
      assert conn.assigns.origin.id == "2167"
      assert conn.assigns.destination.id == "82"
      assert conn.assigns.trip_info
      assert conn.assigns.schedules != nil
      assert conn.assigns.predictions != nil
    end
  end

  describe "commuter rail" do
    test "assigns the tab parameter if none is provided", %{conn: conn} do
      conn = get(conn, schedule_v2_path(conn, :show, "CR-Worcester"))
      assert conn.assigns.tab == "timetable"
    end

    test "assigns information for the trip view", %{conn: conn} do
      conn = get(conn, schedule_v2_path(conn, :show, "CR-Worcester", tab: "trip-view"))
      assert conn.assigns.tab == "trip-view"
      refute conn.assigns.schedules == nil
      refute conn.assigns.from == nil
      refute conn.assigns.predictions == nil
      assert conn.assigns.trip_info
    end

    test "assigns information for the timetable", %{conn: conn} do
      conn = get(conn, schedule_v2_path(conn, :show, "CR-Worcester", tab: "timetable"))
      assert conn.assigns.tab == "timetable"
      refute conn.assigns.offset == nil
      refute conn.assigns.alerts == nil
      assert conn.assigns.trip_info
    end
  end

  describe "subway" do
    test "assigns schedules, frequency table, origin, and destination", %{conn: conn} do
      conn = get(conn, schedule_v2_path(conn, :show, "Red", origin: "place-sstat", destination: "place-brdwy"))
      assert conn.assigns.schedules
      assert conn.assigns.frequency_table
      assert conn.assigns.origin
      assert conn.assigns.destination
    end
  end

end
