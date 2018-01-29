defmodule Content.ExternaRequestTest do
  use ExUnit.Case
  import Content.ExternalRequest

  describe "process/4" do
    test "issues a request with the provided information" do
      bypass = bypass_cms()

      Bypass.expect bypass, fn conn ->
        assert "GET" = conn.method
        assert "/get" == conn.request_path
        assert Plug.Conn.fetch_query_params(conn).params["cake"] == "is the best"
        Plug.Conn.resp(conn, 200, "[]")
      end

      assert {:ok, []} = process(:get, "/get", "", [params: [cake: "is the best"]])
    end

    test "handles a request with a body" do
      bypass = bypass_cms()

      Bypass.expect bypass, fn conn ->
        {:ok, body, %Plug.Conn{}} = Plug.Conn.read_body(conn)
        assert body == "what about pie?"
        Plug.Conn.resp(conn, 201, "{}")
      end

      process(:post, "/post", "what about pie?")
    end

    test "sets headers for GET requests" do
      bypass = bypass_cms()

      Bypass.expect bypass, fn conn ->
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/json"]
        assert Plug.Conn.get_req_header(conn, "authorization") == []
        Plug.Conn.resp(conn, 200, "[]")
      end

      process(:get, "/get")
    end

    test "sets auth headers for non-GET requests" do
      bypass = bypass_cms()

      Bypass.expect bypass, fn conn ->
        [basic_auth_header] = Plug.Conn.get_req_header(conn, "authorization")
        assert basic_auth_header =~ "Basic"
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/json"]
        Plug.Conn.resp(conn, 201, "{}")
      end

      process(:post, "/post", "body")
    end

    test "returns the HTTP response as an error if the request is not successful" do
      bypass = bypass_cms()

      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 404, "{\"message\":\"No page found\"}")
      end

      assert {:error, :not_found} = process(:get, "/page")
    end

    test "returns {:error, :invalid_response} if the request returns an exception" do
      bypass = bypass_cms()

      Bypass.down bypass
      assert process(:get, "/page") == {:error, :invalid_response}
    end

    test "returns {:error, :invalid_response} if the json cannot be parsed" do
      bypass = bypass_cms()

      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "{invalid")
      end

      assert process(:get, "/page") == {:error, :invalid_response}
    end

    test "returns {:error, {:redirect, path}} when CMS issues a native redirect and removes _format=json" do
      bypass = bypass_cms()
      Bypass.expect bypass, fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        redirected_path = "/redirect?" <> URI.encode_query(conn.query_params)
        conn
        |> Plug.Conn.put_resp_header("location", redirected_path)
        |> Plug.Conn.resp(302, "redirecting")
      end

      assert {:error, {:redirect, url}} = process(:get, "/path?_format=json")
      assert url == "/redirect"
    end

    test "path retains query params and removes _format=json when CMS issues a native redirect" do
      bypass = bypass_cms()
      Bypass.expect bypass, fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        redirected_path = "/redirect?" <> URI.encode_query(conn.query_params)
        conn
        |> Plug.Conn.put_resp_header("location", redirected_path)
        |> Plug.Conn.resp(302, "redirecting")
      end

      assert {:error, {:redirect, url}} = process(:get, "/path?_format=json&foo=bar")
      assert url == "/redirect?&foo=bar"
    end
  end

  def bypass_cms do
    original_drupal_config = Application.get_env(:content, :drupal)

    bypass = Bypass.open
    bypass_url = "http://localhost:#{bypass.port}/"

    Application.put_env(
      :content,
      :drupal,
      put_in(original_drupal_config[:root], bypass_url)
    )

    on_exit fn ->
      Application.put_env(:content, :drupal, original_drupal_config)
    end

    bypass
  end
end
