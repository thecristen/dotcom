defmodule Alerts.RepoTest do
  use ExUnit.Case, async: true

  import Alerts.Repo

  @tag :external
  describe "banner/0" do
    test "returns a banner or nil" do
      actual = banner()
      assert match?(%Alerts.Banner{}, actual) or actual == nil
    end
  end

  describe "do_banner/1" do
    test "if there are no items with a banner, returns nil" do
      api = %JsonApi{
        data: [
          %JsonApi.Item{
            id: "id",
            attributes: %{
              "header" => "header",
              "banner" => nil,
              "description" => "description"
            }}]}
      assert do_banner(fn -> api end) == nil
    end

    test "if there are any items with a banner, returns <banner> with the first" do
      api = %JsonApi{
        data: [
          %JsonApi.Item{
            id: "id",
            attributes: %{
              "header" => "header",
              "url" => "url",
              "banner" => "banner",
              "description" => "description"
            }},
          %JsonApi.Item{
            id: "id2",
            attributes: %{
              "header" => "header",
              "banner" => "second banner",
              "description" => "second description"
            }},
        ]}
      banner = %Alerts.Banner{
        id: "id",
        title: "banner",
        url: "url"}
      assert do_banner(fn -> api end) == banner
    end

    test "can return a banner with a nil URL" do
      api = %JsonApi{
        data: [
          %JsonApi.Item{
            id: "id",
            attributes: %{
              "header" => "header",
              "url" => nil,
              "banner" => "banner",
              "description" => "description"
            }},
        ]}
      banner = %Alerts.Banner{
        id: "id",
        title: "banner",
        url: nil}
      assert do_banner(fn -> api end) == banner
    end
  end
end
