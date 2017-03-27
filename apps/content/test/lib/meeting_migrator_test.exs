defmodule Content.MeetingMigratorTest do
  use ExUnit.Case
  import Content.FixtureHelpers
  alias Content.MeetingMigrator

  @filename "cms_migration/meeting.json"

  describe "migrate/2" do
    test "creates an event in the CMS" do
      bypass = bypass_cms()

      Bypass.expect bypass, fn conn ->
        case conn.request_path do
          "/events" ->
            response_data = []
            assert "GET" == conn.method
            assert conn.query_string =~ URI.encode_query(%{meeting_id: 5550})
            Plug.Conn.resp(conn, 200, Poison.encode!(response_data))
          "/entity/node" ->
            response_data = [%{"nid" => [%{"value" => 37}]}]
            assert "POST" == conn.method
            Plug.Conn.resp(conn, 201, Poison.encode!(response_data))
        end
      end

      result = MeetingMigrator.migrate(fixture(@filename))
      assert {:ok, %HTTPoison.Response{status_code: 201}} = result
    end

    test "given the event already exists in the CMS, updates the event" do
      bypass = bypass_cms()

      Bypass.expect bypass, fn conn ->
        response_data = [%{"nid" => [%{"value" => 37}]}]

        case conn.request_path do
          "/events" ->
            assert "GET" == conn.method
            assert conn.query_string =~ URI.encode_query(%{meeting_id: 5550})
            Plug.Conn.resp(conn, 200, Poison.encode!(response_data))
          "/node/37" ->
            assert "PATCH" == conn.method
            Plug.Conn.resp(conn, 200, Poison.encode!(response_data))
        end
      end

      result = MeetingMigrator.migrate(fixture(@filename))
      assert {:ok, %HTTPoison.Response{status_code: 200}} = result
    end
  end

  defp bypass_cms do
    original_drupal_config = Application.get_env(:content, :drupal)

    bypass = Bypass.open
    bypass_url = "http://localhost:#{bypass.port}/"

    Application.put_env(:content, :drupal,
      put_in(original_drupal_config[:root], bypass_url))

    on_exit fn ->
      Application.put_env(:content, :drupal, original_drupal_config)
    end

    bypass
  end
end
