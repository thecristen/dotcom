defmodule Site.BodyTagTest do
  use ExUnit.Case, async: true
  import Site.BodyTag
  import Phoenix.ConnTest, only: [build_conn: 0]
  import Phoenix.HTML, only: [safe_to_string: 1]
  import Plug.Conn, only: [put_req_header: 3, put_private: 3]

  describe "render/1" do
    test "returns no-js by default" do
      assert safe_to_string(render(build_conn())) =~ "no-js"
    end

    test "returns js if the request came from turbolinks" do
      conn = build_conn()
      |> put_req_header("turbolinks-referrer", "referrer")

      assert safe_to_string(render(conn)) =~ "js"
    end

    test "returns js not-found if we get to an error page from turbolinks" do
      conn = build_conn()
      |> put_req_header("turbolinks-referrer", "referrer")
      |> put_private(:phoenix_view, Site.ErrorView)

      assert safe_to_string(render(conn)) =~ "js not-found"
    end

    test "returns mticket if the requisite header is present" do
      conn = build_conn()
      |> put_req_header(Application.get_env(:site, Site.BodyTag)[:mticket_header], "")

      assert safe_to_string(render(conn)) =~ "no-js mticket"
    end
  end
end
