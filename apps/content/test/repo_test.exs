defmodule Content.RepoTest do
  use ExUnit.Case

  @page_body [Path.dirname(__ENV__.file), "fixtures", "page.json"]
  |> Path.join
  |> File.read!

  @events [Path.dirname(__ENV__.file), "fixtures", "events.json"]
  |> Path.join
  |> File.read!

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

  describe "page/1" do
    test "fetches the JSON-formatted page", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert "/page" == conn.request_path
        assert Plug.Conn.fetch_query_params(conn).params["_format"] == "json"
        Plug.Conn.resp(conn, 200, @page_body)
      end

      assert {:ok, %Content.Page{}} = Content.Repo.page("/page")
    end

    test "returns an error if the page isn't found", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 404, @page_body)
      end

      assert {:error, _} = Content.Repo.page("/page")
    end

    test "returns an error if Drupal is down", %{bypass: bypass} do
      Bypass.down(bypass)

      assert {:error, _} = Content.Repo.page("/page")

      Bypass.up(bypass)
    end
  end

  describe "all/2" do
    test "returns all records matching the given path", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 200, @events)
      end

      assert [%Content.Page{}] = Content.Repo.all("events")
    end

    test "returns all records matching the given path and params", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert Plug.Conn.fetch_query_params(conn).params["start-date"] == "2017-01-01"
        Plug.Conn.resp(conn, 200, @events)
      end

      params = %{"start-date" => "2017-01-01"}

      assert [%Content.Page{}] = Content.Repo.all("events", params)
    end

    test "raises an error when given an invalid path", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 404, "Page not found")
      end

      assert_raise Content.ErrorFetchingContent, fn ->
        Content.Repo.all("eventz")
      end
    end
  end

  describe "get/2" do
    test "returns the record for the given id", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 200, @events)
      end

      assert %Content.Page{} = Content.Repo.get("events", 1)
    end

    test "returns nil when a record is not found", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "[]")
      end

      assert Content.Repo.get("events", 999) == nil
    end

    test "raises an error when given an invalid path", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 404, "CMS page not found")
      end

      assert_raise Content.ErrorFetchingContent, fn ->
        Content.Repo.get("eventz", 1)
      end
    end
  end

  describe "get!/2" do
    test "returns the record for the given id", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 200, @events)
      end

      assert %Content.Page{} = Content.Repo.get!("events", 1)
    end

    test "raises an error when the record is not found", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "[]")
      end

      assert_raise Content.NoResultsError, fn ->
        Content.Repo.get!("events", 999) == nil
      end
    end

    test "raises an error when given an invalid path", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 404, "CMS page not found")
      end

      assert_raise Content.ErrorFetchingContent, fn ->
        Content.Repo.get!("eventz", 1)
      end
    end
  end
end
