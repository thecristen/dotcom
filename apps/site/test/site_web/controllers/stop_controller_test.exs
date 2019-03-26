defmodule SiteWeb.StopControllerTest do
  use SiteWeb.ConnCase
  alias Routes.Route
  alias SiteWeb.StopController
  alias Stops.Stop
  alias Util.Breadcrumb

  test "view is under a flag", %{conn: conn} do
    assert conn
           |> get(stop_path(conn, :show, "place-sstat"))
           |> Map.fetch!(:status) == 404

    assert conn
           |> put_req_cookie("stop_page_redesign", "true")
           |> get(stop_path(conn, :show, "place-sstat"))
           |> Map.fetch!(:status) == 200
  end

  test "renders react content server-side", %{conn: conn} do
    assert [{"div", _, content}] =
             conn
             |> put_req_cookie("stop_page_redesign", "true")
             |> get(stop_path(conn, :show, "place-sstat"))
             |> html_response(200)
             |> Floki.find("#react-root")

    assert [_ | _] = content
  end

  test "assigns routes for this stop", %{conn: conn} do
    conn =
      conn
      |> put_req_cookie("stop_page_redesign", "true")
      |> get(stop_path(conn, :show, "place-sstat"))

    assert conn.assigns.routes
  end

  test "assigns the zone number for the current stop", %{conn: conn} do
    conn =
      conn
      |> put_req_cookie("stop_page_redesign", "true")
      |> get(stop_path(conn, :show, "Worcester"))

    assert conn.assigns.zone_number == "8"
  end

  test "sets a custom meta description for stops", %{conn: conn} do
    conn =
      conn
      |> put_req_cookie("stop_page_redesign", "true")
      |> get(stop_path(conn, :show, "place-sstat"))

    assert conn.assigns.meta_description
  end

  test "404s for an unknown stop", %{conn: conn} do
    conn =
      conn
      |> put_req_cookie("stop_page_redesign", "true")
      |> get(stop_path(conn, :show, "unknown"))

    assert Map.fetch!(conn, :status) == 404
  end

  describe "breadcrumbs/2" do
    test "returns station breadcrumbs if the stop is served by more than buses" do
      stop = %Stop{name: "Name", station?: true}
      routes = [%Route{id: "CR-Lowell", type: 2}]

      assert StopController.breadcrumbs(stop, routes) == [
               %Breadcrumb{text: "Stations", url: "/stops-v2/commuter-rail"},
               %Breadcrumb{text: "Name", url: ""}
             ]
    end

    test "returns simple breadcrumb if the stop is served by only buses" do
      stop = %Stop{name: "Dudley Station"}
      routes = [%Route{id: "28", type: 3}]

      assert StopController.breadcrumbs(stop, routes) == [
               %Breadcrumb{text: "Dudley Station", url: ""}
             ]
    end

    test "returns simple breadcrumb if we have no route info for the stop" do
      stop = %Stop{name: "Name", station?: true}
      assert StopController.breadcrumbs(stop, []) == [%Breadcrumb{text: "Name", url: ""}]
    end
  end
end
