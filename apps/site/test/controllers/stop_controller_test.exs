defmodule Site.StopControllerTest do
  use Site.ConnCase, async: true

  alias Site.StopController

  test "redirects to subway stops on index", %{conn: conn} do
    conn = get conn, stop_path(conn, :index)
    assert redirected_to(conn) == stop_path(conn, :show, :subway)
  end

  test "shows stations by mode", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, :subway)
    response = html_response(conn, 200)
    for line <- ["Green", "Red", "Blue", "Orange", "Mattapan"] do
      assert response =~ line
    end
  end

  test "shows stations", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "place-portr")
    assert html_response(conn, 200) =~ "Porter Square"
    assert conn.assigns.breadcrumbs == [
      {stop_path(conn, :index), "Stations"},
      "Porter Square"
    ]
  end

  test "shows stops", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "22")
    assert html_response(conn, 200) =~ "E Broadway @ H St"
    assert conn.assigns.breadcrumbs == [
      "E Broadway @ H St"
    ]
  end

  test "can show stations with spaces", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "Anderson/ Woburn")
    assert html_response(conn, 200) =~ "Anderson/Woburn"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, stop_path(conn, :show, -1)
    end
  end

  test "assigns the terminal station of CR lines from a station", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "Anderson/ Woburn")
    assert conn.assigns.terminal_station == "place-north"
    conn = get conn, stop_path(conn, :show, "Readville")
    assert conn.assigns.terminal_station == "place-sstat"
  end

  test "assigns an empty terminal station for non-CR stations", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "22")
    assert conn.assigns.terminal_station == ""
  end

  describe "access_alerts/2" do
    alias Alerts.Alert
    alias Alerts.InformedEntity, as: IE

    def alerts do
      [
        %Alert{effect_name: "Delay", informed_entity: [%IE{route: "Red", stop: "place-sstat"}]},
        %Alert{effect_name: "Access Issue", informed_entity: [%IE{stop: "place-pktrm"}]},
        %Alert{effect_name: "Access Issue", informed_entity: [%IE{stop: "place-sstat"}, %IE{route: "Red"}]}
      ]
    end

    test "returns only access issues which affect the given stop" do
      assert StopController.access_alerts(alerts, %Stops.Stop{id: "place-sstat"}) == [
        %Alert{effect_name: "Access Issue", informed_entity: [%IE{stop: "place-sstat"}, %IE{route: "Red"}]}
      ]
      assert StopController.access_alerts(alerts, %Stops.Stop{id: "place-davis"}) == []
    end
  end
end
