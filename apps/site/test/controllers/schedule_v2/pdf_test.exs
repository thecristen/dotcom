defmodule Site.ScheduleV2Controller.PdfTest do
  use Site.ConnCase, async: true

  test "redirects to PDF for route when present", %{conn: conn} do
    conn = get(conn, route_pdf_path(conn, :pdf, %Routes.Route{id: "CR-Fitchburg"}))
    assert redirected_to(conn, 302) == "https://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Commuter_Rail/fitchburg.pdf"
  end

  test "renders 404 if route doesn't exist", %{conn: conn} do
    conn = get(conn, route_pdf_path(conn, :pdf, %Routes.Route{id: "Nonexistent"}))
    assert html_response(conn, 404)
  end

  test "renders 404 if route exists but does not have PDF", %{conn: conn} do
    conn = get(conn, route_pdf_path(conn, :pdf, %Routes.Route{id: "57A"}))
    assert html_response(conn, 404)
  end
end
