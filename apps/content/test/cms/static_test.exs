defmodule Content.CMS.StaticTest do
  use ExUnit.Case
  import Content.CMS.Static

  describe "view/2" do
    test "stubs /news when given a page parameter and returns valid json" do
      assert {:ok, [record]} = view("/news", page: 1)
      assert record_type(record) == "news_entry"
    end

    test "redirects" do
      assert {:error, {:redirect, _}} = view("/redirected-url", %{})
      assert {:error, {:redirect, _}} = view("/news/redirected-url", %{})
      assert {:error, {:redirect, _}} = view("/events/redirected-url", %{})
      assert {:error, {:redirect, _}} = view("/projects/redirected-project", %{})
      assert {:error, {:redirect, _}} = view("/projects/project-name/update/redirected-update", %{})
    end
  end

  describe "redirect/2" do
    test "redirects with params if they exist" do
      assert redirect("path", %{}) == {:error, {:redirect, "path"}}
    end

    test "redirects without params if they do not exist" do
      assert redirect("path", %{"foo" => "bar"}) == {:error, {:redirect, "path?foo=bar"}}
    end
  end

  defp record_type(%{"type" => [%{"target_id" => type}]}), do: type
end
