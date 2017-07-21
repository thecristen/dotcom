defmodule Mix.Tasks.Backstop.Update do
  use Mix.Task

  @shortdoc "Update Backstop references."
  @moduledoc """
  With no arguments, updates all failed references from the most recent test run. If arguments are given,
  they should be a list of filenames to update.
  """

  @reference_dir "apps/site/test/backstop_data/bitmaps_test"

  def run(files) do
    test_dir = latest_test_dir()
    test_dir
    |> File.ls!
    |> filter_file_list(files)
    |> join_paths(test_dir)
    |> Enum.each(&copy_file/1)
  end

  defp latest_test_dir do
    @reference_dir
    |> File.ls!
    |> join_paths(@reference_dir)
    |> Enum.filter(&File.dir?/1)
    |> Enum.max
  end

  @doc "Join a root path to a list of filenames"
  def join_paths(paths, root) do
    for path <- paths, do: Path.expand(path, root)
  end

  @doc "Either find the failed files, or filter to a list of provided files"
  def filter_file_list(directory_files, []) do
    latest_failures(directory_files)
  end
  def filter_file_list(directory_files, file_list) do
    for file <- directory_files,
      file in file_list do
        file
    end
  end

  defp latest_failures(files) do
    for file <- files,
      String.starts_with?(file, "failed_diff_") do
        String.replace_prefix(file, "failed_diff_", "")
    end
  end

  defp copy_file(path) do
    File.cp! path, destination_path(path)
  end

  @doc "Path for the reference image of a given test image"
  def destination_path(path) do
    filename = Path.basename(path)

    [@reference_dir, "../bitmaps_reference", filename]
    |> Path.join
    |> Path.expand
  end
end
