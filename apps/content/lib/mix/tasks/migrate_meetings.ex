defmodule Mix.Tasks.Content.MigrateMeetings do
  use Mix.Task
  alias Content.CmsMigration.MeetingMigrator

  @shortdoc "Migrates existing data for meetings to the new CMS."

  @moduledoc """
  When running this task, use the CMS system account. Ask in Slack for
  the system account username and password.
  Example usage:
  ```
  env DRUPAL_ROOT=http://mbta.kbox.site \
  DRUPAL_USERNAME=username \
  DRUPAL_PASSWORD=password \
  mix content.migrate_meetings ~/path/to/meeting/files/*.json
  ```
  """

  @spec run(String.t) :: String.t | no_return
  def run(directory_path) do
    Mix.Task.run "app.start"

    directory_path
    |> json_files
    |> migrate_meetings(directory_path)
  end

  defp migrate_meetings([filename | remaining_filenames], file_location) do
    meeting_json = parse_file(file_location, filename)

    case MeetingMigrator.migrate(meeting_json) do
      {:ok, response} ->
        print_response(response, filename)
        migrate_meetings(remaining_filenames, file_location)
      {:error, reason} ->
        print_response(reason, filename)
        notify_developers(reason, meeting_json)
    end
  end
  defp migrate_meetings([], _file_location) do
    Mix.shell.info "All meetings have been migrated."
  end

  defp json_files(directory_path) do
    directory_path
    |> files_in_directory
    |> filter_json_files
  end

  defp files_in_directory(directory_path) do
    case File.ls(directory_path) do
      {:ok, files} -> files
      {:error, _enoent} -> raise_with_instructions()
    end
  end

  defp filter_json_files(files) do
    files
    |> Enum.filter(fn(file) ->
      String.ends_with?(file, ".json")
    end)
  end

  defp parse_file(directory_path, filename) do
    [directory_path, filename]
    |> Path.join()
    |> File.read!
    |> Poison.Parser.parse!()
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
    Content.Mailer.meeting_migration_error_notice(reason, meeting_json)
  end

  defp raise_with_instructions do
    Mix.raise """
    Oops! Looks like the path you provided does not exist.
    Please provide a valid path to the directory containing
    the meeting json files you wish to migrate to the new CMS.
    """
  end
end
