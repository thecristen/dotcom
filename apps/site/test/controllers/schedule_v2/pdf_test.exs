defmodule Site.ScheduleV2Controller.PdfTest do
  use Site.ConnCase, async: true

  import Site.Router.Helpers, only: [static_url: 2, route_pdf_path: 3]
  alias Plug.Conn

  @date ~D[2018-01-01]

  describe "pdf/2" do
    test "redirects to PDF for route when present", %{conn: conn} do
      expected_path = "/sites/default/files/route_pdfs/route087.pdf"
      conn = conn
      |> Conn.assign(:date, @date)
      |> get(route_pdf_path(conn, :pdf, "87"))
      assert redirected_to(conn, 302) == static_url(Site.Endpoint, expected_path)
    end

    test "renders 404 if we have no pdfs for the route", %{conn: conn} do
      conn = conn
      |> Conn.assign(:date, @date)
      |> get(route_pdf_path(conn, :pdf, "nonexistent"))
      assert html_response(conn, 404)
    end

    test "cleanly handles errors from the api", %{conn: conn} do
      conn = conn
      |> Conn.assign(:date, @date)
      |> get(route_pdf_path(conn, :pdf, "error"))
      assert html_response(conn, 404)
    end
  end
end
