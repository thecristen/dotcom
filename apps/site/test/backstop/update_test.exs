defmodule Backstop.UpdateTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import Mix.Tasks.Backstop.Update

  describe "join_paths/2" do
    test "adds the expanded path to the filenames" do
      expected = ["/app/root/one", "/app/root/two"]
      actual = join_paths(~w(one two), "/app/root")
      assert actual == expected
    end
  end

  describe "filter_file_list/2" do
    @list [
      "not_failed.png",
      "failed_diff_original.png"]

    test "given a list of filenames, returns only the matching names" do
      expected = ["not_failed.png"]
      actual = filter_file_list(@list, ["not_failed.png", "missing.png"])
      assert actual == expected
    end

    test "without specified filenames, returns the failed ones" do
      expected = ["original.png"]
      actual = filter_file_list(@list, [])
      assert actual == expected
    end
  end

  describe "destination_path/1" do
    test "finds the path for the file in the reference directory" do
      expected = "#{File.cwd!}/apps/site/backstop_data/bitmaps_reference/filename.png"
      actual = destination_path(
        "apps/site/backstop_data/bitmaps_test/20170626-110918/filename.png")
      assert actual == expected
    end
  end
end
