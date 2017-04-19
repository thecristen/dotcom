defmodule Content.CmsMigration.MeetingMigratorTest do
  use ExUnit.Case
  import Content.FixtureHelpers
  alias Content.CmsMigration.MeetingMigrator
  alias Content.CmsMigration.MeetingMigrationError

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

      previously_migrated_meeting =
        @filename
        |> fixture
        |> Map.put("meeting_id", "1")

      Bypass.expect bypass, fn conn ->
        response_data = [%{"nid" => [%{"value" => 17}]}]
        assert conn.request_path == "/node/17"
        assert "PATCH" == conn.method
        Plug.Conn.resp(conn, 200, Poison.encode!(response_data))
      end

      result = MeetingMigrator.migrate(previously_migrated_meeting)
      assert {:ok, %HTTPoison.Response{status_code: 200}} = result
    end

    test "does not migrate the event if the start time is greater than the end time" do
      meeting_with_invalid_time_range =
        @filename
        |> fixture
        |> Map.put("meettime", "4:00 PM - 2:00 PM")

      error = ~r/The start time must be less than the end time/
      assert_raise MeetingMigrationError, error, fn ->
        MeetingMigrator.migrate(meeting_with_invalid_time_range)
      end
    end

    test "does not migrate the event if the start time is missing" do
      missing_start_time =
        @filename
        |> fixture
        |> Map.put("meettime", "")

      error = "A start time must be provided."
      assert_raise MeetingMigrationError, error, fn ->
        MeetingMigrator.migrate(missing_start_time)
      end
    end
  end

  describe "check_for_existing_event!/1" do
    test "returns the event id, when an existing event is found" do
      assert MeetingMigrator.check_for_existing_event!("1") == 17
    end

    test "when an existing record is not found" do
      assert MeetingMigrator.check_for_existing_event!("999") == nil
    end

    test "when multiple records are found" do
      expected_error_message = "multiple records were found when querying by meeting_id: multiple-records."

      assert_raise MeetingMigrationError, expected_error_message, fn ->
        MeetingMigrator.check_for_existing_event!("multiple-records")
      end
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
