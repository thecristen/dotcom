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

  describe "show_fares?/1" do
    test "Do not show fare information for Origin stations" do
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

  describe "mode_summaries/3" do
    test "commuter summaries only include commuter mode" do
      summaries = StopView.mode_summaries(:commuter, {:zone, "7"}, [])
      assert Enum.all?(summaries, fn(summary) -> summary.modes == [:commuter] end)
    end
    test "Bus summaries only return bus fare information" do
      summaries = StopView.mode_summaries(:bus_subway, {:bus, ""}, [:bus, :commuter, :ferry])
      assert Enum.all?(summaries, fn summary -> summary.modes == [:bus] end)
    end
    test "Bus_subway summaries only return bus and subway information" do
      summaries = StopView.mode_summaries(:bus_subway, {:bus, ""}, [:subway, :commuter, :ferry])
      assert Enum.all?(summaries, fn summary -> :subway in summary.modes && :bus in summary.modes end)
    end
  end
end
