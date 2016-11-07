defmodule Site.BodyClassTest do
  use ExUnit.Case, async: true
  import Site.BodyClass, only: [class_name: 1]
  import Phoenix.ConnTest, only: [build_conn: 0]
  import Plug.Conn, only: [put_req_header: 3, put_private: 3]

  describe "class_name/1" do
    test "returns no-js by default" do
      assert class_name(build_conn()) == "no-js"
    end

    test "returns js if the request came from turbolinks" do
      conn = build_conn
      |> put_req_header("turbolinks-referrer", "referrer")

      assert class_name(conn) == "js"
    end

    test "returns js not-found if we get to an error page from turbolinks" do
      conn = build_conn
      |> put_req_header("turbolinks-referrer", "referrer")
      |> put_private(:phoenix_view, Site.ErrorView)

      assert class_name(conn) == "js not-found"
    end

    test "returns mticket if the requisite header is present" do
      conn = build_conn
      |> put_req_header(Application.get_env(:site, Site.BodyClass)[:mticket_header], "")

      assert class_name(conn) == "no-js mticket"
    end
  end
end
