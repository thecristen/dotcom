defmodule Site.StationViewTest do
  @moduledoc false
  alias Site.StationView
  use Site.ConnCase, async: true

  describe "fare_group/1" do
    test "return correct fare group for all modes" do
      assert StationView.fare_group(:bus) == "bus_subway"
      assert StationView.fare_group(:subway) == "bus_subway"
      assert StationView.fare_group(:commuter) == "commuter"
      assert StationView.fare_group(:ferry) == "ferry"
    end
  end

  describe "template_for_tab/1" do
    test "correct template for selected tab" do
      assert StationView.template_for_tab(nil) == "_schedule.html"
      assert StationView.template_for_tab("info") == "_info.html"
      assert StationView.template_for_tab("schedule") == "_schedule.html"
    end
  end

  describe "tab_class/2" do
    test "CSS class for selected tab" do
      selected_class = "stations-tab stations-tab-selected"
      non_selected_class = "stations-tab"
      assert StationView.tab_class("schedule", nil) == selected_class
      assert StationView.tab_class("info", nil) == non_selected_class
      assert StationView.tab_class("schedule", "info") == non_selected_class
      assert StationView.tab_class("info", "info") == selected_class
    end
  end
end
