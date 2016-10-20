defmodule Site.StyleGuideControllerTest do
  use Site.ConnCase
  
  test "the same json file names exist in priv/static/css and web/static/css" do
    assert get_json_files(css_folder_path) == get_json_files(priv_folder_path)
  end

  test "the contents of the json files in priv/static/css and web/static/css are identical" do
    assert read_json_files(css_folder_path) == read_json_files(priv_folder_path)
  end

  def css_folder_path do
    File.cwd!
    |> String.split("/apps/site")
    |> List.first
    |> Path.join("/apps/site/web/static/css")
  end

  def priv_folder_path do
    :site
    |> Application.app_dir
    |> Path.join("/priv/static/css")
  end

  def get_json_files(parent_folder) do
    parent_folder
    |> File.ls!
    |> Enum.filter(&(Path.extname(&1) == ".json"))
  end

  def get_json_paths(parent_folder) do
    parent_folder
    |> get_json_files
    |> Enum.map(&(Path.join(parent_folder, &1)))
  end

  def read_json_files(parent_folder) do
    parent_folder
    |> get_json_paths
    |> Enum.map(&File.read!/1)
  end
end
