defmodule Content.CmsMigration.MeetingMigratorTest do
  use ExUnit.Case
  import Content.JsonHelpers
  alias Content.CmsMigration.MeetingMigrator
  alias Content.MigrationError

  @filename "fixtures/cms_migration/valid_meeting/meeting.json"

  describe "migrate/2" do
    test "creates an event in the CMS" do
      meeting_data = parse_json_file(@filename)
      assert {:ok, :created} = MeetingMigrator.migrate(meeting_data)
    end

    test "given the event already exists in the CMS, updates the event" do
      previously_migrated_meeting =
        @filename
        |> parse_json_file()
        |> Map.put("meeting_id", "1")

      assert {:ok, :updated} = MeetingMigrator.migrate(previously_migrated_meeting)
    end

    test "when the event fails to create" do
      invalid_meeting =
        @filename
        |> parse_json_file()
        |> Map.put("objective", "fails-to-create")

      assert {:error, %{status_code: 422}} = MeetingMigrator.migrate(invalid_meeting)
    end

    test "when the event fails to update" do
      id_for_existing_record = "1"

      invalid_meeting =
        @filename
        |> parse_json_file()
        |> Map.put("objective", "fails-to-update")
        |> Map.put("meeting_id", id_for_existing_record)

      assert {:error, %{status_code: 422}} = MeetingMigrator.migrate(invalid_meeting)
    end

    test "does not migrate the event if the start time is greater than the end time" do
      meeting_with_invalid_time_range =
        @filename
        |> parse_json_file()
        |> Map.put("meettime", "4:00 PM - 2:00 PM")

      result = MeetingMigrator.migrate(meeting_with_invalid_time_range)
      assert {:error, "The start time must be less than the end time."} = result
    end

    test "does not migrate the event if the start time is missing" do
      missing_start_time =
        @filename
        |> parse_json_file()
        |> Map.put("meettime", "")

      result = MeetingMigrator.migrate(missing_start_time)
      assert {:error, "A start time must be provided."} = result
    end

    test "when querying for an existing record returns more than one record" do
      record_with_non_unique_meeting_id =
        @filename
        |> parse_json_file()
        |> Map.put("meeting_id", "multiple-records")

      expected_error_message = "multiple records were found when querying by meeting_id: multiple-records."

      assert_raise MigrationError, expected_error_message, fn ->
        MeetingMigrator.migrate(record_with_non_unique_meeting_id)
      end
    end
  end
end
