defmodule Alerts.RepoTest do
  use ExUnit.Case

  import Alerts.Repo

  setup do
    clear_cache()
  end

  @tag :external
  describe "all/0" do
    test "returns an empty list if there's an error fetching the alerts" do
      v3_url = Application.get_env(:v3_api, :base_url)
      on_exit fn ->
        Application.put_env(:v3_api, :base_url, v3_url)
      end

      Application.put_env(:v3_api, :base_url, "http://localhost:0")

      assert all() == []
    end

    test "returns a list of alerts" do
      alerts = all()
      assert is_list(alerts)
      for alert <- alerts do
        assert %Alerts.Alert{} = alert
      end
    end

    test "returns the alerts sorted" do
      alerts = all()
      assert alerts == Alerts.Sort.sort(alerts)
    end
  end

  @tag :external
  describe "banner/0" do
    test "returns nil if there's an error fetching the banner" do
      v3_url = Application.get_env(:v3_api, :base_url)
      on_exit fn ->
        Application.put_env(:v3_api, :base_url, v3_url)
      end

      Application.put_env(:v3_api, :base_url, "http://localhost:0")

      refute banner()
    end

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
