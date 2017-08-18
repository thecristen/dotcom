defmodule Site.HowToPayControllerTest do
  use Site.ConnCase, async: true
  import Site.PageHelpers, only: [breadcrumbs_include?: 2]

  describe "index" do
    test "renders", %{conn: conn} do
      conn = get conn, how_to_pay_path(conn, :index)
      assert html_response(conn, 200) =~ "How to Pay"
    end

    test "includes breadcrumbs on default page", %{conn: conn} do
      conn = get conn, how_to_pay_path(conn, :index)

      body = html_response(conn, 200)
      assert breadcrumbs_include?(body, ["Fares and Passes", "How to Pay"])
    end

    test "includes breadcrumbs on commuter rail tab", %{conn: conn} do
      conn = get conn, how_to_pay_path(conn, :show, :commuter_rail)

      body = html_response(conn, 200)
      assert breadcrumbs_include?(body, ["Fares and Passes", "How to Pay"])
    end

    test "redirects unknown modes to the index page", %{conn: conn} do
      conn = get conn, how_to_pay_path(conn, :show, "non-existent-986419624")
      assert redirected_to(conn) == how_to_pay_path(conn, :index)
    end
  end
end
