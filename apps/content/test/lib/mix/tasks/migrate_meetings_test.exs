defmodule Content.MigrateMeetingsTest do
  use Content.EmailCase
  import Mock
  import Content.FixtureHelpers
  alias Content.CmsMigration.MeetingMigrator

  @meeting "cms_migration/meeting.json"
  @other_meeting "cms_migration/meeting_missing_end_time.json"

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit fn ->
      Mix.shell(Mix.Shell.IO)
    end

    directory_path = Path.join([File.cwd!, "test", "fixtures", "cms_migration"])
    {:ok, path: directory_path}
  end

  test "creates or updates events in the CMS, based on the provided json files", %{path: path} do
    response = {:ok, %HTTPoison.Response{status_code: 201}}

    with_mock MeetingMigrator, [migrate: fn(_map) -> response end] do
      Mix.Tasks.Content.MigrateMeetings.run(path)

      assert called MeetingMigrator.migrate(fixture(@meeting))
      assert called MeetingMigrator.migrate(fixture(@other_meeting))
      refute email_sent_with_subject("Meeting Migration Task Failed")
    end
  end

  test "prints helpful message when an event is successfully created", %{path: path} do
    response = {:ok, %HTTPoison.Response{status_code: 201}}

    with_mock MeetingMigrator, [migrate: fn(_map) -> response end] do
      Mix.Tasks.Content.MigrateMeetings.run(path)
      assert_received {:mix_shell, :info, ["Successfully created" <> _filename]}
    end
  end

  test "prints a helpful message when an event is successfully updated", %{path: path} do
    response = {:ok, %HTTPoison.Response{status_code: 200}}

    with_mock MeetingMigrator, [migrate: fn(_map) -> response end] do
      Mix.Tasks.Content.MigrateMeetings.run(path)
      assert_received {:mix_shell, :info, ["Successfully updated" <> _filename]}
    end
  end

  test "prints a helpful message when an event fails to migrate", %{path: path} do
    error_response = {:error, %HTTPoison.Response{status_code: 422}}

    with_mock MeetingMigrator, [migrate: fn(_map) -> error_response end] do
      Mix.Tasks.Content.MigrateMeetings.run(path)
      assert_received {:mix_shell, :info, ["The following error occurred" <> _filename]}
    end
  end

  test "sends an email to developers when an event fails to migrate", %{path: path} do
    error_response = {:error, %HTTPoison.Response{status_code: 422}}

    with_mock MeetingMigrator, [migrate: fn(_map) -> error_response end] do
      Mix.Tasks.Content.MigrateMeetings.run(path)
      assert email_sent_with_subject("Meeting Migration Task Failed")
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
