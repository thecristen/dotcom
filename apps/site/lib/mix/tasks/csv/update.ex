defmodule Mix.Tasks.Csv.Update.Zones do
  @moduledoc """
  Takes the current CR Zone csv, looks up any child stops via Repo, adds them to the csv
  """
  use Mix.Task
  alias Mix.Tasks.FileWrapper
  alias Stops.{Repo, Stop}

  @output_folder Application.app_dir(:zones, "priv/")
  @original_file Application.app_dir(:zones, "priv/crzones_without_children.csv")
  def run(args) do
    {opts, [], []} = OptionParser.parse(args, switches: [output_folder: :string, csv: :string])

    output_folder = Keyword.get(opts, :output_folder, @output_folder)
    original_file = Keyword.get(opts, :original_file, @original_file)

    # To use repo
    {:ok, _} = Application.ensure_all_started(:site)

    original = FileWrapper.read_file(original_file)

    csv_parent =
      original
      |> String.split("\n", trim: true)
      |> CSV.decode(headers: [:id, :zone])
      |> Enum.map(fn {:ok, row} -> row end)

    child_stops =
      csv_parent
      |> Enum.map(fn parent -> {get_children(parent), parent.zone} end)
      |> Enum.reject(fn {children, _zone} -> is_nil(children) end)
      |> Enum.flat_map(fn {children, zone} ->
        Enum.map(children, fn child -> [child, zone] end)
      end)

    final = child_stops |> CSV.encode() |> Enum.join()

    FileWrapper.write_file(Path.join(output_folder, "crzones.csv"), original <> final)
  end

  def child_ids(%Stop{child_ids: []}), do: nil
  def child_ids(%Stop{child_ids: ids}), do: ids

  def get_children(%{id: id, zone: _}) do
    children = id |> Repo.get() |> child_ids

    if children do
      Enum.reject(children, &(Repo.get(&1).type == :entrance))
    else
      nil
    end
  end
end
