defmodule Mix.Tasks.Backstop.Update do
  use Mix.Task

  @shortdoc "Update Backstop references."
  @moduledoc """
  With no arguments, updates all failed references from the most recent test run. If arguments are given,
  they should be a list of filenames to update.
  """

  @reference_dir "apps/site/backstop_data/bitmaps_test"

  def run([]) do
    latest_test_dir()
    |> latest_failures
    |> Enum.each(&copy_file/1)
  end
  def run(filenames) do
    test_dir = latest_test_dir()

    filenames
    |> Enum.map(fn path ->
      Path.expand(Path.join(test_dir, path))
    end)
    |> Enum.each(&copy_file/1)
  end

  def latest_test_dir do
    @reference_dir
    |> File.ls!
    |> Enum.sort
    |> Enum.map(&Path.join(@reference_dir, &1))
    |> Enum.filter(&File.dir?/1)
    |> List.last
  end

  def latest_failures(dir) do
    dir
    |> File.ls!
    |> Enum.filter(&Kernel.=~(&1, "failed_diff_"))
    |> Enum.map(fn path ->
      ~r/^failed_diff_(.*)$/
      |> Regex.run(path, capture: :all_but_first)
      |> List.first
      |> (fn f -> Path.expand(Path.join(dir, f)) end).()
    end)
  end

  def copy_file(path) do
    filename = path
    |> Path.split
    |> List.last

    destination = [@reference_dir, "../bitmaps_reference", filename]
    |> Path.join
    |> Path.expand

    :ok = File.cp path, destination
  end
end
