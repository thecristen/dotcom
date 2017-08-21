defmodule Content.BreadcrumbsTest do
  use ExUnit.Case, async: true
  import Content.Breadcrumbs

  describe "build/1" do
    test "returns a list of breadcrumbs" do
      data = %{
        "breadcrumbs" => [
          %{
            "text" => "Home",
            "uri" => "/"
          },
          %{
            "text" => "Current Crumb",
            "uri" => ""
          }
        ]
      }

      assert [
        %Util.Breadcrumb{text: "Home", url: "/"},
        %Util.Breadcrumb{text: "Current Crumb", url: ""}
      ] = build(data)
    end

    test "when breadcrumbs are missing" do
      assert [] = build(%{})
    end
  end
end
