defmodule Alerts.RepoTest do
  use ExUnit.Case

  describe "all/0" do
    test "returns the list of alerts from the store" do
      Alerts.Cache.Store.update([%Alerts.Alert{id: "alert!"}], nil)
      assert [%Alerts.Alert{id: "alert!"}] = Alerts.Repo.all()
    end
  end

  describe "banner/0" do
    test "returns the banner if present" do
      Alerts.Cache.Store.update([], %Alerts.Banner{})
      assert %Alerts.Banner{} = Alerts.Repo.banner()
    end

    test "returns nil if no banner" do
      Alerts.Cache.Store.update([], nil)
      assert nil == Alerts.Repo.banner()
    end
  end

  describe "by_route_ids/1" do
    @orange_entity %Alerts.InformedEntity{route: "Orange"}
    @red_entity %Alerts.InformedEntity{route: "Red"}
    @blue_entity %Alerts.InformedEntity{route: "Blue"}

    test "returns the list of alerts from the store with the given route_ids" do
      orange_alert = %Alerts.Alert{id: "orange_alert", informed_entity: [@orange_entity]}
      red_alert = %Alerts.Alert{id: "red_alert", informed_entity: [@red_entity]}
      blue_alert = %Alerts.Alert{id: "blue_alert", informed_entity: [@blue_entity]}
      Alerts.Cache.Store.update([orange_alert, red_alert, blue_alert], nil)
      alerts = Alerts.Repo.by_route_ids(["Orange", "Red"])

      assert orange_alert in alerts
      assert red_alert in alerts
      refute blue_alert in alerts
    end
  end
end
