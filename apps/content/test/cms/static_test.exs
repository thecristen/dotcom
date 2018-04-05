defmodule Content.CMS.StaticTest do
  use ExUnit.Case
  import Content.CMS.Static

  describe "view/2" do
    test "stubs /news when given a page parameter and returns valid json" do
      assert {:ok, [record]} = view("/cms/news", page: 1)
      assert record_type(record) == "news_entry"
    end

    test "/projects/project-deleted/update/project-deleted-update" do
      assert {:ok, %{"field_project" => [project]}} = view("/projects/project-deleted/update/project-deleted-progress", %{})
      assert %{"url" => "/projects/project-deleted"} = project
    end

    test "redirects" do
      assert {:error, {:redirect, 302, _}} = view("/redirected-url", %{})
      assert {:error, {:redirect, 301, _}} = view("/news/redirected-url", %{})
      assert {:error, {:redirect, 301, _}} = view("/events/redirected-url", %{})
      assert {:error, {:redirect, 301, _}} = view("/projects/redirected-project", %{})
      assert {:error, {:redirect, 301, _}} = view("/projects/project-name/update/redirected-update", %{})
      assert {:error, {:redirect, 301, _}} = view("/node/3519", %{})
      assert {:error, {:redirect, 301, _}} = view("/node/3268", %{})
      assert {:error, {:redirect, 301, _}} = view("/node/3005", %{})
      assert {:error, {:redirect, 301, _}} = view("/node/3174", %{})
      assert {:error, {:redirect, 301, _}} = view("/node/3004", %{})
    end
  end

  describe "redirect/3" do
    test "redirects with params if they exist" do
      assert redirect("path", %{}, 302) == {:error, {:redirect, 302, "path"}}
    end

    test "redirects without params if they do not exist" do
      assert redirect("path", %{"foo" => "bar"}, 302) == {:error, {:redirect, 302, "path?foo=bar"}}
    end
  end

  defp record_type(%{"type" => [%{"target_id" => type}]}), do: type
end
