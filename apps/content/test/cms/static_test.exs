defmodule Content.CMS.StaticTest do
  use ExUnit.Case
  import Content.CMS.Static

  describe "view/2" do
    test "stubs /news when given a page parameter and returns valid json" do
      assert {:ok, [record]} = view("/news", page: 1)
      assert record_type(record) == "news_entry"
    end
  end

  defp record_type(%{"type" => [%{"target_id" => type}]}), do: type
end
