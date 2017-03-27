defmodule Mix.Tasks.Content.MigrateMeetings do
  use Mix.Task

  @shortdoc "Migrates existing data for meetings to the new CMS."

  @moduledoc """
  When running this task, use the CMS system account. Ask in Slack for
  the system account username and password.
  Example usage:
  ```
  env DRUPAL_ROOT=http://mbta.kbox.site \
  env DRUPAL_USERNAME=username \
  env DRUPAL_PASSWORD=password \
  mix content.migrate_meetings ~/path/to/meeting/files/*.json
  ```
  """

  @spec run(String.t) :: String.t | no_return
  def run(directory_path) do
    Mix.Task.run "app.start"

    filenames = json_files(directory_path)

    for filename <- filenames do
      directory_path
      |> parse_file(filename)
      |> Content.MeetingMigrator.migrate()
      |> print_response(filename)
    end
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

  defp print_response({:ok, %HTTPoison.Response{status_code: 200}}, filename) do
    Mix.shell.info "#{filename} successfully updated."
  end
  defp print_response({:ok, %HTTPoison.Response{status_code: 201}}, filename) do
    Mix.shell.info "#{filename} successfully created."
  end
  defp print_response(response, filename) do
    Mix.raise """
      The following error occurred when migrating #{filename}.
      #{inspect response}
    """
  end

  defp raise_with_instructions do
    Mix.raise """
    Oops! Looks like the path you provided does not exist.
    Please provide a valid path to the directory containing
    the meeting json files you wish to migrate to the new CMS.
    """
  end
end
