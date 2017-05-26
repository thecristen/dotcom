defmodule Mix.Tasks.Content.MigrateNews do
  use Mix.Task
  alias Content.CmsMigration.NewsMigrator
  alias Content.CmsMigration.MigrationFile

  @shortdoc "Migrates News Entry records from the old CMS to the new CMS."

  @moduledoc """
  When running this task, use the CMS system account. Ask in Slack for
  the system account username and password.
  Example usage:
  ```
  env DRUPAL_ROOT=http://mbta.kbox.site \
  DRUPAL_USERNAME=username \
  DRUPAL_PASSWORD=password \
  mix content.migrate_news ~/path/to/news/json/files/
  ```
  """

  @spec run(String.t) :: String.t | no_return
  def run(directory_path) do
    Mix.Task.run "app.start"

    case MigrationFile.filter_json_files(directory_path) do
      {:error, _error} -> raise_with_instructions()
      files -> migrate_news(files, directory_path)
    end
  end

  defp migrate_news([filename | remaining_filenames], directory_path) do
    {:ok, news_entry_json} = MigrationFile.parse_file(directory_path, filename)

    case NewsMigrator.migrate(news_entry_json) do
      {:ok, response} ->
        print_response(response, filename)
        migrate_news(remaining_filenames, directory_path)
      {:error, reason} ->
        print_response(reason, filename)
        notify_developers(reason, news_entry_json)
    end
  end
  defp migrate_news([], _file_location) do
    Mix.shell.info "All News Entries have been migrated."
  end

  defp print_response(:updated, filename) do
    Mix.shell.info "Successfully updated #{filename}."
  end
  defp print_response(:created, filename) do
    Mix.shell.info "Successfully created #{filename}."
  end
  defp print_response(response, filename) do
    Mix.shell.info """
    The following error occurred when migrating #{filename}.
    #{inspect response}
    """
  end

  defp notify_developers(reason, meeting_json) do
    Content.Mailer.migration_error_notice(reason, meeting_json)
  end

  defp raise_with_instructions do
    Mix.raise """
    Oops! Looks like the path you provided does not exist.
    Please provide a valid path to the directory containing
    the news json files you wish to migrate to the new CMS.
    """
  end
end
