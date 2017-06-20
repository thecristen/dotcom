defmodule Content.MigrateNewsTest do
  use Content.EmailCase

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit fn ->
      Mix.shell(Mix.Shell.IO)
    end
  end

  test "migrates news data from json files to the CMS" do
    path = path("valid_news_entry")

    Mix.Tasks.Content.MigrateNews.run([path])
    assert_received {:mix_shell, :info, ["All News Entries have been migrated."]}
    refute email_sent_with_subject("News Migration Task Failed")
  end

  test "prints helpful message when a News Entry is successfully migrated" do
    path = path("valid_news_entry")

    Mix.Tasks.Content.MigrateNews.run([path])
    assert_received {:mix_shell, :info, ["Successfully migrated" <> _filename]}
  end

  test "prints a helpful message when a News Entry fails to migrate" do
    path = path("invalid_news_entry")

    Mix.Tasks.Content.MigrateNews.run([path])
    assert_received {:mix_shell, :info, ["The following error occurred" <> _filename]}
  end

  test "sends an email to developers when a News Entry fails to migrate" do
    path = path("invalid_news_entry")

    Mix.Tasks.Content.MigrateNews.run([path])
    assert email_sent_with_subject("CMS Migration Task Failed")
  end

  test "sends an email to developers when migrating a news entry raised an error" do
    path = path("exceptional_news_entry")

    Mix.Tasks.Content.MigrateNews.run([path])
    assert email_sent_with_subject("CMS Migration Task Failed")
  end

  test "raises with instructions when an invalid directory path is provided" do
    assert_raise Mix.Error, ~r/path you provided does not exist/, fn ->
      Mix.Tasks.Content.MigrateNews.run(["invalid/path"])
    end
  end

  test "raises with instructions when a directory path is not provided" do
    assert_raise Mix.Error, ~r/path you provided does not exist/, fn ->
      Mix.Tasks.Content.MigrateNews.run([])
    end
  end

  defp path(directory_name) do
    Path.join([File.cwd!, "test", "fixtures", "cms_migration", directory_name])
  end
end
