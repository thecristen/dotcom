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

  describe "by_route_ids/1" do
    @commuter_rail_entity %Alerts.InformedEntity{route_type: 2}
    @bus_entity %Alerts.InformedEntity{route_type: 3}
    @subway_entity %Alerts.InformedEntity{route_type: 0}

    test "returns the list of alerts from the store with the given types" do
      commuter_rail_alert = %Alerts.Alert{id: "commuter_rail_alert", informed_entity: [@commuter_rail_entity]}
      bus_alert = %Alerts.Alert{id: "bus_alert", informed_entity: [@bus_entity]}
      subway_alert = %Alerts.Alert{id: "subway_alert", informed_entity: [@subway_entity]}
      Alerts.Cache.Store.update([commuter_rail_alert, bus_alert, subway_alert], nil)
      alerts = Alerts.Repo.by_route_types([2, 0])

      assert commuter_rail_alert in alerts
      assert subway_alert in alerts
      refute bus_alert in alerts
    end
  end
end
