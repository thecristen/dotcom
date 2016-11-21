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

  describe "fare_mode/1" do
    test "types are separated as bus, subway or both" do
      assert StopView.fare_mode([:bus, :commuter, :ferry]) == :bus
      assert StopView.fare_mode([:subway, :commuter, :ferry]) == :subway
      assert StopView.fare_mode([:subway, :commuter, :ferry, :bus]) == :bus_subway
    end
  end

  describe "accessibility_info" do
    test "Accessibility description reflects features" do
      no_accessibility = %Stops.Stop{name: "test", accessibility: nil}
      no_accessible_feature = %Stops.Stop{id: "north", name: "test", accessibility: []}
      only_accessible_feature = %Stops.Stop{name: "test", accessibility: ["accessible"]}
      many_feature = %Stops.Stop{name: "test", accessibility: ["accessible", "ramp", "elevator"]}
      tag_has_text = fn(tag, text) -> Phoenix.HTML.safe_to_string(Enum.at(tag, 0)) =~ text end

      assert tag_has_text.(StopView.accessibility_info(no_accessibility), "No accessibility")
      assert tag_has_text.(StopView.accessibility_info(no_accessible_feature), "No accessibility")
      assert tag_has_text.(StopView.accessibility_info(only_accessible_feature), "wheeled mobility devices")
      assert tag_has_text.(StopView.accessibility_info(many_feature), "has the following")
    end
  end

  describe "mode_summaries/2" do
    test "commuter summaries only include commuter mode" do
      summaries = StopView.mode_summaries(:commuter, {:zone, "7"})
      assert Enum.all?(summaries, fn(summary) -> summary.modes == [:commuter] end)
    end
    test "Bus summaries only return bus fare information" do
      summaries = StopView.mode_summaries(:bus, {:bus, ""})
      assert Enum.all?(summaries, fn summary -> summary.modes == [:bus] end)
    end
    test "Bus_subway summaries return both bus and subway information" do
      summaries = StopView.mode_summaries(:bus_subway, {:bus, ""})
      mode_present = fn(summary, mode) -> mode in summary.modes end
      assert Enum.any?(summaries, &(mode_present.(&1,:bus))) && Enum.any?(summaries, &(mode_present.(&1,:subway)))
    end
  end

  describe "aggregate_routes/1" do
    test "All green line routes are aggregated" do
      e_line = %{name: "Green-E"}
      d_line = %{name: "Green-D"}
      c_line = %{name: "Green-C"}
      orange_line = %{name: "Orange"}
      line_list = [e_line, d_line, c_line, orange_line]
      green_count = line_list |> Site.StopView.aggregate_routes |> Enum.filter(&(&1.name == "Green")) |> Enum.count

      assert green_count == 1
      assert Enum.count(Site.StopView.aggregate_routes(line_list)) == 2
    end
  end

  describe "schedule_display_time/2" do
    test "returns difference in minutes when difference is less than 60" do
      now = Util.now
      diff = Timex.shift(now, minutes: 10)
      |> StopView.schedule_display_time(now)
      assert diff == "10 mins"
    end

    test "returns formatted time when difference is greater than 60" do
      now = Util.now
      time = Timex.shift(now, hours: 2)
      diff = time
      |> StopView.schedule_display_time(now)
      assert diff == time |> Timex.format!("{h12}:{m} {AM}")
    end
  end
end
