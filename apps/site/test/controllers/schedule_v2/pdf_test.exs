defmodule Site.ScheduleV2Controller.PdfTest do
  use Site.ConnCase, async: true

  test "redirects to PDF for route when present", %{conn: conn} do
    route = %Routes.Route{id: "CR-Fitchburg"}
    conn = get(conn, route_pdf_path(conn, :pdf, route))
    assert redirected_to(conn, 302) == Routes.Pdf.url(route)
  end

  test "renders 404 if route doesn't exist", %{conn: conn} do
    conn = get(conn, route_pdf_path(conn, :pdf, %Routes.Route{id: "Nonexistent"}))
    assert html_response(conn, 404)
  end

  test "renders 404 if route exists but does not have PDF", %{conn: conn} do
    # 195 is a secret route - https://en.wikipedia.org/wiki/List_of_MBTA_bus_routes#195
    route = %Routes.Route{id: "195"}
    conn = get(conn, route_pdf_path(conn, :pdf, route))
    assert html_response(conn, 404)
    conn = get(conn, route_pdf_path(conn, :pdf, route, date: "2017-01-01"))
    assert html_response(conn, 404)
  end

  test "redirects to a newer URL given a date", %{conn: conn} do
    route = %Routes.Route{id: "CR-Lowell"}
    [{first_date, first_url}, {second_date, second_url} | _] = Routes.Pdf.dated_urls(route, ~D[2017-01-01])

    conn = get(conn, route_pdf_path(conn, :pdf, route, date: Date.to_iso8601(first_date)))
    assert redirected_to(conn, 302) == first_url

    conn = get(conn, route_pdf_path(conn, :pdf, route, date: Date.to_iso8601(second_date)))
    assert redirected_to(conn, 302) == second_url
  end

  test "returns 404 if the date does not parse", %{conn: conn} do
    route = %Routes.Route{id: "CR-Lowell"}
    conn = get(conn, route_pdf_path(conn, :pdf, route, date: "not_valid"))
    assert html_response(conn, 404)
  end
end
