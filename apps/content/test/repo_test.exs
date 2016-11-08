defmodule Content.RepoTest do
  use ExUnit.Case

  @page_body __ENV__.file
  |> Path.dirname
  |> Path.join("fixtures")
  |> Path.join("page.json")
  |> File.read!

  setup_all _ do
    original_drupal_root = Application.get_env(:content, :drupal_root)
    bypass = Bypass.open
    Application.put_env(:content, :drupal_root, "http://localhost:#{bypass.port}")

    on_exit fn ->
      Application.put_env(:content, :drupal_root, original_drupal_root)
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
end
