defmodule Content.MigrateMeetingsTest do
  use ExUnit.Case
  import Mock
  import Content.FixtureHelpers
  import ExUnit.CaptureIO
  alias Content.CmsMigration.MeetingMigrator

  @meeting "cms_migration/meeting.json"
  @other_meeting "cms_migration/meeting_missing_end_time.json"

  setup do
    directory_path = Path.join([File.cwd!, "test", "fixtures", "cms_migration"])
    {:ok, path: directory_path}
  end

  test "creates or updates events in the CMS, based on the provided json files", %{path: path} do
    response = {:ok, %HTTPoison.Response{status_code: 201}}

    with_mock MeetingMigrator, [migrate: fn(_map) -> response end] do
      capture_io(fn ->
        Mix.Tasks.Content.MigrateMeetings.run(path)
      end)

      assert called MeetingMigrator.migrate(fixture(@meeting))
      assert called MeetingMigrator.migrate(fixture(@other_meeting))
    end
  end

  test "prints helpful message when an event is successfully created", %{path: path} do
    response = {:ok, %HTTPoison.Response{status_code: 201}}

    with_mock MeetingMigrator, [migrate: fn(_map) -> response end] do
      assert capture_io(fn ->
        Mix.Tasks.Content.MigrateMeetings.run(path)
      end) =~ "successfully created"
    end
  end

  test "prints a helpful message when an event is successfully updated", %{path: path} do
    response = {:ok, %HTTPoison.Response{status_code: 200}}

    with_mock MeetingMigrator, [migrate: fn(_map) -> response end] do
      assert capture_io(fn ->
        Mix.Tasks.Content.MigrateMeetings.run(path)
      end) =~ "successfully updated"
    end
  end

  test "raises an error when an event is unsuccessfully migrated", %{path: path} do
    error_response = {:ok, %HTTPoison.Response{status_code: 422}}

    with_mock MeetingMigrator, [migrate: fn(_map) -> error_response end] do
      assert_raise Mix.Error, ~r/status_code: 422/, fn ->
        Mix.Tasks.Content.MigrateMeetings.run(path)
      end
    end
  end

  test "raises with instructions when an invalid directory path is provided" do
    error_message = """
    Oops! Looks like the path you provided does not exist.
    Please provide a valid path to the directory containing
    the meeting json files you wish to migrate to the new CMS.
    """

    assert_raise Mix.Error, error_message, fn ->
      Mix.Tasks.Content.MigrateMeetings.run("invalid/path")
    end
  end
end
