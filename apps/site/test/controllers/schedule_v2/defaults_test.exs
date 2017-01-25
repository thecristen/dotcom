defmodule Site.ScheduleV2Controller.DefaultsTest do
  use Site.ConnCase, async: true
  alias Site.ScheduleV2Controller.Defaults
  alias Routes.Route
  alias Stops.Stop

  setup %{conn: conn} do
    conn =
      conn
      |> assign(:route, %Route{id: "1", type: 3})
      |> assign(:date_time, Util.now())
      |> assign(:date, Util.service_date())
      |> fetch_query_params()
    {:ok, conn: conn}
  end

  describe "assigns headsigns to" do
    test "correct headsigns if route has been assigned", %{conn: conn} do
      conn = Defaults.call(conn, [])
      assert conn.assigns.headsigns == %{0 => ["Harvard"], 1 => ["Dudley"]}
    end
  end

  describe "assigns origin to" do
    test "nil when id not in params", %{conn: conn} do
      conn = Defaults.call(conn, [])
      assert conn.assigns.origin == nil
    end

    test "a %Stop{} when id in params", %{conn: conn} do
      conn = Defaults.call(%{conn | query_params: %{"origin" => "2167", "direction_id" => "1"}}, [])
      assert %Stop{id: "2167"} = conn.assigns.origin
    end
  end

  describe "assigns destination to" do
    test "nil when id not in params", %{conn: conn} do
      conn = Defaults.call(conn, [])
      assert conn.assigns.destination == nil
    end

    test "a %Stop{} when id in params", %{conn: conn} do
      conn = Defaults.call(%{conn | query_params: %{"origin" => "64", "destination" => "place-hymnl", "direction_id" => "0"}}, [])
      assert %Stop{id: "place-hymnl"} = conn.assigns.destination
     end
  end

  describe "assigns show_date_select? to" do
    test "false when not in params", %{conn: conn} do
      conn = Defaults.call(conn, [])
      assert conn.assigns.show_date_select? == false
    end

    test "true when true in params", %{conn: conn} do
      conn = %{conn | params: %{"date_select" => "true"}}
      conn = Defaults.call(conn, [])
      assert conn.assigns.show_date_select? == true
    end
  end

  describe "assign direction_id to" do
    test "integer when in params", %{conn: conn} do
      conn = Defaults.call(%{conn | query_params: %{"direction_id" => "1"}}, [])
      assert conn.assigns.direction_id == 1
    end

    test "0 when id is not in params and after 1:59pm", %{conn: conn} do
      conn = conn
      |> assign(:date_time, ~N[2017-01-25T14:00:00])
      |> Defaults.call([])
      assert conn.assigns.direction_id == 0
    end

    test "1 when id is not in params and before 1:59pm", %{conn: conn} do
      conn = conn
      |> assign(:date_time, ~N[2017-01-25T13:00:00])
      |> Defaults.call([])
      assert conn.assigns.direction_id == 1
    end
  end

  describe "assures that stops exist based on direction:" do
    test "when both origin and destination exist, assigns both as %Stop{} structs", %{conn: conn} do
      conn = Defaults.call(%{conn | params: %{"route" => "1"}, query_params: %{"origin" => "place-hymnl", "destination" => "64", "direction_id" => "1"}}, [])
      refute conn.assigns.origin == nil
      assert conn.assigns.origin.id == "place-hymnl"
      refute conn.assigns.destination == nil
      assert conn.assigns.destination.id == "64"
      assert conn.assigns.direction_id == 1
    end

    test "when origin exists and there's no destination, origin is a %Stop{} and destination is nil", %{conn: conn} do
      conn = Defaults.call(%{conn | params: %{"route" => "1"}, query_params: %{"origin" => "place-hymnl", "direction_id" => "1"}}, [])
      refute conn.assigns.origin == nil
      assert conn.assigns.origin.id == "place-hymnl"
      assert conn.assigns.destination == nil
      assert conn.assigns.direction_id == 1
    end

    test "when origin does not exist, redirects to schedules_v2 page with no stops selected", %{conn: conn} do
      path = schedule_v2_path(conn, :show, "1")
      conn = Defaults.call(%{conn | request_path: path,
                                    params: %{"route" => "1"},
                                    query_params: %{"origin" => "87", "destination" => "64", "direction_id" => "1"}}, [])
      assert redirected_to(conn, 302) == path <> "?direction_id=1"
    end

    test "when neither origin or destination exist, redirects to schedules_v2 page with no stops selected", %{conn: conn} do
      path = schedule_v2_path(conn, :show, "1")
      conn = Defaults.call(%{conn | params: %{"route" => "1"},
                             request_path: path,
                             query_params: %{"origin" => "87", "destination" => "101", "direction_id" => "1"}}, [])
      assert redirected_to(conn, 302) == path <> "?direction_id=1"
    end
  end

  describe "assign_origin/2" do
    test "redirects if passed invalid origin", %{conn: conn} do
      conn = %{conn | query_params: %{"origin" => "87"}, request_path: "/schedules_v2/1"}
             |> assign(:route, %Routes.Route{id: "1"})
             |> assign(:direction_id, 1)
             |> Defaults.assign_origin([])
      assert redirected_to(conn, 302) == "/schedules_v2/1"
    end
  end
end
