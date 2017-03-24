defmodule Site.BodyTagTest do
  use ExUnit.Case, async: true
  import Site.BodyTag
  import Phoenix.ConnTest, only: [build_conn: 0]
  import Plug.Conn, only: [put_req_header: 3, put_private: 3]

  describe "render/1" do
    test "returns no-js and sticky-footer by default" do
      assert render(build_conn()) =~ "no-js sticky-footer"
    end

    test "returns js if the request came from turbolinks" do
      conn = build_conn()
      |> put_req_header("turbolinks-referrer", "referrer")

      assert render(conn) =~ "js sticky-footer"
    end

    test "does not return sticky-footer on homepage" do
      class =
        build_conn()
        |> put_private(:phoenix_view, Site.PageView)
        |> put_private(:phoenix_template, "index.html")
        |> render()
      assert class =~ "no-js"
    end

    test "returns js not-found if we get to an error page from turbolinks" do
      conn = build_conn()
      |> put_req_header("turbolinks-referrer", "referrer")
      |> put_private(:phoenix_view, Site.ErrorView)

      assert render(conn) =~ "js not-found sticky-footer"
    end

    test "returns mticket if the requisite header is present" do
      conn = build_conn()
      |> put_req_header(Application.get_env(:site, Site.BodyTag)[:mticket_header], "")

      assert render(conn) =~ "no-js mticket sticky-footer"
    end
  end
end
