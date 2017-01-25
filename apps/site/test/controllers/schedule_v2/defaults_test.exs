defmodule Site.ScheduleV2.DefaultsTest do
  use Site.ConnCase, async: true
  alias Site.ScheduleV2.Defaults
  alias Routes.Route

  setup %{conn: conn} do
    {:ok, conn: assign(conn, :route, %Route{type: 3})}
  end

  describe "assign date_select to" do
    test "false when date_select not in params", %{conn: conn} do
      conn = Defaults.call(conn, [])
      assert conn.assigns.date_select == false
    end

    test "true when date_select in params", %{conn: conn} do
      conn = %{conn | params: %{"date_select" => "true"}}
      conn = Defaults.call(conn, [])
      assert conn.assigns.date_select == true
    end
  end

  test "assign route_type to integer when route has been assigned", %{conn: conn} do
    conn = Defaults.call(conn, [])
    assert conn.assigns.route_type == 3
  end
end
