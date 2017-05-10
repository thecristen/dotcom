defmodule Content.CmsMigration.MigrationFileTest do
  use ExUnit.Case
  import Content.CmsMigration.MigrationFile

  setup do
    File.mkdir_p!(tmp_path())
    on_exit(fn -> File.rm_rf(tmp_path()) end)
    :ok
  end

  describe "filter_json_files/2" do
    test "returns files with a .json extension" do
      _json_file = tmp_file("example.json")
      _non_json_file = tmp_file("example.txt")

      assert ["example.json"] = filter_json_files(tmp_path())
    end

    test "given an invalid directory" do
      assert {:error, :enoent} = filter_json_files("foo")
    end
  end

  describe "parse_file/2" do
    test "parses the given file" do
      filename = "example.json"
      tmp_file(filename, ~s({"name": "Burt Macklin"}))

      assert {:ok, %{"name" => "Burt Macklin"}} = parse_file(tmp_path(), filename)
    end

    test "given an non-existant file" do
      assert {:error, :enoent} = parse_file(tmp_path(), "doesnotexist.json")
    end

    test "given a file that fails to parse" do
      filename = "example.json"
      tmp_file(filename, "")

      assert {:error, :invalid} = parse_file(tmp_path(), filename)
    end
  end

  defp tmp_path do
    Path.expand("../../tmp", __DIR__)
  end

  defp tmp_path(filename) do
    Path.join(tmp_path(), filename)
  end

  defp tmp_file(filename) do
    path = Path.join(tmp_path(), filename)
    File.touch(path)
  end

  defp tmp_file(filename, content) do
    path = tmp_path(filename)
    File.write(path, content)
  end
end
