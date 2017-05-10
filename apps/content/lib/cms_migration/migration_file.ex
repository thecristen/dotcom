defmodule Content.CmsMigration.MigrationFile do
  @spec filter_json_files(String.t) :: list | {:error, term}
  def filter_json_files(directory_path) do
    with {:ok, files} <- File.ls(directory_path) do
      Enum.filter(files, fn(file) -> Path.extname(file) == ".json" end)
    end
  end

  @spec parse_file(String.t, String.t) :: map | {:error, term}
  def parse_file(directory_path, filename) do
    full_path = Path.join(directory_path, filename)

    with {:ok, content} <- File.read(full_path) do
      Poison.Parser.parse(content)
    end
  end
end
