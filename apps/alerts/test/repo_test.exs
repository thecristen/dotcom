defmodule Alerts.RepoTest do
  use ExUnit.Case, async: true

  import Alerts.Repo

  @tag :external
  describe "banner/0" do
    test "returns a banner or nil" do
      actual = banner
      assert match?(%Alerts.Banner{}, actual) or actual == nil
    end
  end

  describe "do_banner/1" do
    test "if there are no items with a banner, returns {:ok, nil}" do
      api = %JsonApi{
        data: [
          %JsonApi.Item{
            id: "id",
            attributes: %{
              "header" => "header",
              "banner" => nil,
              "description" => "description"
            }}]}
      assert do_banner(fn -> api end) == {:ok, nil}
    end

    test "if there are any items with a banner, returns {:ok, <banner>} with the first" do
      api = %JsonApi{
        data: [
          %JsonApi.Item{
            id: "id",
            attributes: %{
              "header" => "header",
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
        description: "description"}
      assert do_banner(fn -> api end) == {:ok, banner}
    end
  end
end
