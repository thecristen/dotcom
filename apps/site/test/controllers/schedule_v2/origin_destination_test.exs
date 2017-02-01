defmodule Site.ScheduleV2Controller.OriginDestinationTest do
  use Site.ConnCase, async: true
  alias Site.ScheduleV2Controller.OriginDestination
  alias Routes.Route

  defp setup_conn(conn) do
    conn
    |> assign(:route, %Route{id: "1", type: 3})
    |> assign(:date_time, Util.now())
    |> assign(:date, Util.service_date())
    |> fetch_query_params()
    |> Site.ScheduleV2Controller.Defaults.call([])
    |> OriginDestination.call([])
  end

  describe "assigns origin to" do
    test "nil when id not in params", %{conn: conn} do
      conn = setup_conn(conn)
      assert conn.assigns.origin == nil
    end

    test "a %Stop{} when id in params", %{conn: conn} do
      conn = setup_conn(%{conn | query_params: %{"origin" => "2167", "direction_id" => "1"}})
      assert %Stop{id: "2167"} = conn.assigns.origin
    end
  end

  describe "assigns destination to" do
    test "nil when id not in params", %{conn: conn} do
      conn = setup_conn(conn)
      assert conn.assigns.destination == nil
    end

    test "a %Stop{} when id in params", %{conn: conn} do
      conn = setup_conn(
        %{conn |
          query_params: %{"origin" => "64", "destination" => "place-hymnl", "direction_id" => "0"}
        }
      )
      assert %Stop{id: "place-hymnl"} = conn.assigns.destination
     end
  end

  describe "assures that stops exist based on direction:" do
    test "when both origin and destination exist, assigns both as %Stop{} structs", %{conn: conn} do
      conn = setup_conn(
        %{conn |
          params: %{"route" => "1"},
          query_params: %{"origin" => "place-hymnl", "destination" => "64", "direction_id" => "1"}
        }
      )

      refute conn.assigns.origin == nil
      assert conn.assigns.origin.id == "place-hymnl"
      refute conn.assigns.destination == nil
      assert conn.assigns.destination.id == "64"
      assert conn.assigns.direction_id == 1
    end

    test "when origin exists and there's no destination, origin is a %Stop{} and destination is nil", %{conn: conn} do
      conn = setup_conn(
        %{conn |
          params: %{"route" => "1"},
          query_params: %{"origin" => "place-hymnl", "direction_id" => "1"}
        }
      )
      refute conn.assigns.origin == nil
      assert conn.assigns.origin.id == "place-hymnl"
      assert conn.assigns.destination == nil
      assert conn.assigns.direction_id == 1
    end

    test "when origin does not exist, redirects to schedules_v2 page with no stops selected", %{conn: conn} do
      path = schedule_v2_path(conn, :show, "1")
      conn = setup_conn(
        %{conn |
          request_path: path,
          params: %{"route" => "1"},
          query_params: %{"origin" => "87", "destination" => "64", "direction_id" => "1"}
        }
      )
      assert redirected_to(conn, 302) == path <> "?direction_id=1"
    end

    test "when neither origin or destination exist, redirects to schedules_v2 page with no stops selected", %{conn: conn} do
      path = schedule_v2_path(conn, :show, "1")
      conn = setup_conn(
        %{conn |
          params: %{"route" => "1"},
          request_path: path,
          query_params: %{"origin" => "87", "destination" => "101", "direction_id" => "1"}
        }
      )
      assert redirected_to(conn, 302) == path <> "?direction_id=1"
    end
  end
end
