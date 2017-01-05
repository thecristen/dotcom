defmodule Site.Plugs.HolidaysTest do
  use Site.ConnCase, async: true

  import Site.Plugs.Holidays

  describe "init/1" do
    test "Returns default" do
      assert init([]) == []
    end
  end

  describe "call/2" do
    test "Holidays are assigned when date is assigned", %{conn: conn} do
      conn = %{conn | assigns: %{date: ~D[2017-01-04]}}
      |> call([])

      assert Enum.count(conn.assigns.holidays) == 3
    end

    test "Conn is halted when no date is given", %{conn: conn} do
      conn = conn
      |> call([])

      assert conn.halted
    end
  end
end
