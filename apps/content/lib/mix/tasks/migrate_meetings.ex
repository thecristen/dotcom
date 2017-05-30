defmodule Mix.Tasks.Content.MigrateMeetings do
  use Mix.Task
  alias Content.CmsMigration.MeetingMigrator
  alias Content.CmsMigration.MigrationFile

  @shortdoc "Migrates existing data for meetings to the new CMS."

  @moduledoc """
  When running this task, use the CMS system account. Ask in Slack for
  the system account username and password.
  Example usage:
  ```
  env DRUPAL_ROOT=http://mbta.kbox.site \
  DRUPAL_USERNAME=username \
  DRUPAL_PASSWORD=password \
  mix content.migrate_meetings ~/path/to/meeting/json/files/
  ```
  """

  def run([directory_path]) do
    Mix.Task.run "app.start"

    case MigrationFile.filter_json_files(directory_path) do
      {:error, _error} -> raise_with_instructions()
      files -> migrate_meetings(files, directory_path)
    end
  end
  def run(_) do
    raise_with_instructions()
  end

  defp migrate_meetings([filename | remaining_filenames], directory_path) do
    {:ok, meeting_json} = MigrationFile.parse_file(directory_path, filename)

    case MeetingMigrator.migrate(meeting_json) do
      {:ok, response} ->
        print_response(response, filename)
        migrate_meetings(remaining_filenames, directory_path)
      {:error, reason} ->
        print_response(reason, filename)
        notify_developers(reason, meeting_json)
    end
  end
  defp migrate_meetings([], _directory_path) do
    Mix.shell.info "All meetings have been migrated."
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

  @spec raise_with_instructions :: no_return
  defp raise_with_instructions do
    Mix.raise """
    Oops! Looks like the path you provided does not exist.
    Please provide a valid path to the directory containing
    the meeting json files you wish to migrate to the new CMS.
    """
  end
end
