defmodule Site.ScheduleController.DefaultsTest do
  use Site.ConnCase, async: true

  alias Site.ScheduleController.Defaults

  @opts Defaults.init([])

  setup %{conn: conn} do
    conn = assign(conn, :date, Util.today)
    {:ok, %{conn: conn}}
  end

  describe "direction_id" do
    test "is 0 if there's no headsign for direction 1", %{conn: conn} do
      conn = conn
      |> fetch_query_params
      |> assign(:headsigns, %{1 => [], 0 => ["Headsign"]})
      |> Defaults.call(@opts)

      assert conn.assigns.direction_id == 0
    end

    test "is 1 if there's no headsign for direction 0", %{conn: conn} do
      conn = conn
      |> fetch_query_params
      |> assign(:headsigns, %{1 => ["Headsign"], 0 => []})
      |> Defaults.call(@opts)

      assert conn.assigns.direction_id == 1
    end
  end
end
