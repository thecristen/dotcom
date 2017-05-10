defmodule Content.MigrateMeetingsTest do
  use Content.EmailCase

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit fn ->
      Mix.shell(Mix.Shell.IO)
    end
  end

  test "migrates meeting data from json files to the CMS" do
    path = path("valid_meeting")

    Mix.Tasks.Content.MigrateMeetings.run(path)
    assert_received {:mix_shell, :info, ["All meetings have been migrated."]}
    refute email_sent_with_subject("Meeting Migration Task Failed")
  end

  test "prints helpful message when an event is successfully created" do
    path = path("valid_meeting")

    Mix.Tasks.Content.MigrateMeetings.run(path)
    assert_received {:mix_shell, :info, ["Successfully created" <> _filename]}
  end

  test "prints a helpful message when an event is successfully updated" do
    path = path("already_migrated_meeting")

    Mix.Tasks.Content.MigrateMeetings.run(path)
    assert_received {:mix_shell, :info, ["Successfully updated" <> _filename]}
  end

  test "prints a helpful message when an event fails to migrate" do
    path = path("invalid_meeting")

    Mix.Tasks.Content.MigrateMeetings.run(path)
    assert_received {:mix_shell, :info, ["The following error occurred" <> _filename]}
  end

  test "sends an email to developers when an event fails to migrate" do
    path = path("invalid_meeting")

    Mix.Tasks.Content.MigrateMeetings.run(path)
    assert email_sent_with_subject("CMS Migration Task Failed")
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

  defp path(directory_name) do
    Path.join([File.cwd!, "test", "fixtures", "cms_migration", directory_name])
  end
end
