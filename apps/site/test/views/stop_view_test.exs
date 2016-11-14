defmodule Site.StopViewTest do
  @moduledoc false
  alias Site.StopView
  use Site.ConnCase, async: true

  describe "fare_group/1" do
    test "return correct fare group for all modes" do
      assert StopView.fare_group(:bus) == "bus_subway"
      assert StopView.fare_group(:subway) == "bus_subway"
      assert StopView.fare_group(:commuter) == "commuter"
      assert StopView.fare_group(:ferry) == "ferry"
    end
  end

  describe "template_for_tab/1" do
    test "correct template for selected tab" do
      assert StopView.template_for_tab(nil) == "_schedule.html"
      assert StopView.template_for_tab("info") == "_info.html"
      assert StopView.template_for_tab("schedule") == "_schedule.html"
    end
  end

  describe "tab_class/2" do
    test "CSS class for selected tab" do
      selected_class = "stations-tab stations-tab-selected"
      non_selected_class = "stations-tab"
      assert StopView.tab_class("schedule", nil) == selected_class
      assert StopView.tab_class("info", nil) == non_selected_class
      assert StopView.tab_class("schedule", "info") == non_selected_class
      assert StopView.tab_class("info", "info") == selected_class
    end
  end

  describe "external_link/1" do
    test "Protocol is added when one is not included" do
      assert StopView.external_link("http://www.google.com") == "http://www.google.com"
      assert StopView.external_link("www.google.com") == "http://www.google.com"
      assert StopView.external_link("https://google.com") == "https://google.com"
    end
  end

  describe "show_fares?/1" do
    test "Only return false for origin destinations" do
      north_station = %Stops.Stop{id: "place-north"}
      back_bay = %Stops.Stop{id: "place-bbsta"}
      salem = %Stops.Stop{id: "Salem"}
      westborough = %Stops.Stop{id: "Westborough"}

      assert !StopView.show_fares?(north_station)
      assert !StopView.show_fares?(back_bay)
      assert StopView.show_fares?(salem)
      assert StopView.show_fares?(westborough)
    end
  end
end
