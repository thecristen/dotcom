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

    Mix.Tasks.Content.MigrateMeetings.run([path])
    assert_received {:mix_shell, :info, ["All meetings have been migrated."]}
    refute email_sent_with_subject("Meeting Migration Task Failed")
  end

  test "prints helpful message when an event is successfully migrated" do
    path = path("valid_meeting")

    Mix.Tasks.Content.MigrateMeetings.run([path])
    assert_received {:mix_shell, :info, ["Successfully migrated" <> _filename]}
  end

  test "prints a helpful message when an event fails to migrate" do
    path = path("invalid_meeting")

    Mix.Tasks.Content.MigrateMeetings.run([path])
    assert_received {:mix_shell, :info, ["The following error occurred" <> _filename]}
  end

  test "notifies developers when migrating an event returns an error" do
    path = path("invalid_meeting")

    Mix.Tasks.Content.MigrateMeetings.run([path])
    assert email_sent_with_subject("CMS Migration Task Failed")
  end

  test "notifies developers when migrating an event raised an error" do
    path = path("exceptional_meeting")

    Mix.Tasks.Content.MigrateMeetings.run([path])
    assert email_sent_with_subject("CMS Migration Task Failed")
  end

  test "raises with instructions when an invalid directory path is provided" do
    assert_raise Mix.Error, ~r/path you provided does not exist/, fn ->
      Mix.Tasks.Content.MigrateMeetings.run(["invalid/path"])
    end
  end

  test "raises with instructions when a directory path is not provided" do
    assert_raise Mix.Error, ~r/path you provided does not exist/, fn ->
      Mix.Tasks.Content.MigrateMeetings.run([])
    end
  end

  defp path(directory_name) do
    Path.join([File.cwd!, "test", "fixtures", "cms_migration", directory_name])
  end
end
