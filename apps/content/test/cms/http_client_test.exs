defmodule Content.CMS.HTTPClientTest do
  use ExUnit.Case

  @page_json File.read!("priv/accessibility.json")

  setup_all _ do
    original_drupal_config = Application.get_env(:content, :drupal)
    bypass = Bypass.open
    Application.put_env(:content, :drupal,
      put_in(original_drupal_config[:root], "http://localhost:#{bypass.port}"))

    on_exit fn ->
      Application.put_env(:content, :drupal, original_drupal_config)
    end

    %{bypass: bypass}
  end

  describe "view/2" do
    test "Returns {:ok, parsed} if it all works", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert "/page" == conn.request_path
        assert Plug.Conn.fetch_query_params(conn).params["_format"] == "json"
        assert Plug.Conn.fetch_query_params(conn).params["foo"] == "bar"
        Plug.Conn.resp(conn, 200, @page_json)
      end

      assert {:ok, %{}} = Content.CMS.HTTPClient.view("/page", foo: "bar")
    end

    test "Returns error tuple if HTTP status code is not successful", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert "/page" == conn.request_path
        assert Plug.Conn.fetch_query_params(conn).params["_format"] == "json"
        Plug.Conn.resp(conn, 404, "{\"message\":\"No page found\"}")
      end

      assert {:error, "HTTP status was 404"} = Content.CMS.HTTPClient.view("/page")
    end

    test "Returns error tuple if HTTP request fails", %{bypass: bypass} do
      Bypass.down bypass
      assert {:error, "Unknown error with HTTP request"} = Content.CMS.HTTPClient.view("/page")
      Bypass.up bypass
    end

    test "Returns error tuple if parsing failure", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert "/page" == conn.request_path
        assert Plug.Conn.fetch_query_params(conn).params["_format"] == "json"
        Plug.Conn.resp(conn, 200, "{invalid")
      end

      assert {:error, "Could not parse JSON response"} = Content.CMS.HTTPClient.view("/page")
    end

    test "Returns error tuple if no Content.Config.root setup" do
      original_config = Application.get_env(:content, :drupal)
      Application.put_env(:content, :drupal, put_in(original_config[:root], nil))

      assert {:error, "No content root configured"} = Content.CMS.HTTPClient.view("/not-found")

      Application.put_env(:content, :drupal, original_config)
    end

    test "Still works if given host has trailing slash as well", %{bypass: bypass} do
      original_config = Application.get_env(:content, :drupal)
      Application.put_env(:content, :drupal,
        put_in(original_config[:root], original_config[:root] <> "/"))

      Bypass.expect bypass, fn conn ->
        assert "/page" == conn.request_path
        assert Plug.Conn.fetch_query_params(conn).params["_format"] == "json"
        Plug.Conn.resp(conn, 200, @page_json)
      end

      assert {:ok, %{}} = Content.CMS.HTTPClient.view("/page")

      Application.put_env(:content, :drupal, original_config)
    end
  end
end
