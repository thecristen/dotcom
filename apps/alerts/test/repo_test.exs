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
end
