defmodule Site.StopViewTest do
  @moduledoc false
  import Site.StopView
  alias Stops.Stop
  use Site.ConnCase, async: true

  describe "fare_group/1" do
    test "return correct fare group for all modes" do
      assert fare_group(:bus) == "bus_subway"
      assert fare_group(:subway) == "bus_subway"
      assert fare_group(:commuter_rail) == "commuter_rail"
      assert fare_group(:ferry) == "ferry"
    end
  end

  describe "template_for_tab/1" do
    test "correct template for selected tab" do
      assert template_for_tab(nil) == "_schedule.html"
      assert template_for_tab("info") == "_info.html"
      assert template_for_tab("schedule") == "_schedule.html"
    end
  end

  describe "tab_selected?/2" do
    test "true for the selected tab, false otherwise" do
      assert tab_selected?("schedule", nil)
      refute tab_selected?("info", nil)
      refute tab_selected?("schedule", "info")
      assert tab_selected?("info", "info")
    end
  end

  describe "fare_mode/1" do
    test "types are separated as bus, subway or both" do
      assert fare_mode([:bus, :commuter_rail, :ferry]) == :bus
      assert fare_mode([:subway, :commuter_rail, :ferry]) == :subway
      assert fare_mode([:subway, :commuter_rail, :ferry, :bus]) == :bus_subway
    end
  end

  describe "accessibility_info" do
    test "Accessibility description reflects features" do
      no_accessibility = %Stop{name: "test", accessibility: nil}
      no_accessible_feature = %Stop{id: "north", name: "test", accessibility: []}
      only_accessible_feature = %Stop{name: "test", accessibility: ["accessible"]}
      many_feature = %Stop{name: "test", accessibility: ["accessible", "ramp", "elevator"]}
      tag_has_text = fn(tag, text) -> Phoenix.HTML.safe_to_string(Enum.at(tag, 0)) =~ text end

      assert tag_has_text.(accessibility_info(no_accessibility), "No accessibility")
      assert tag_has_text.(accessibility_info(no_accessible_feature), "No accessibility")
      assert tag_has_text.(accessibility_info(only_accessible_feature), "is an accessible station")
      assert tag_has_text.(accessibility_info(many_feature), "has the following")
    end
  end

  describe "pretty_accessibility/1" do
    test "formats phone and escalator fields" do
      assert pretty_accessibility("tty_phone") == "TTY Phone"
      assert pretty_accessibility("escalator_both") == "Escalator (Both)"
    end

    test "For all other fields, separates underscore and capitalizes all words" do
      assert pretty_accessibility("elevator_issues") == "Elevator Issues"
      assert pretty_accessibility("down_escalator_repair_work") == "Down Escalator Repair Work"
    end
  end

  describe "sort_parking_spots/1" do
    test "parkings spots are sorted in correct order" do
      basic_spot = %{type: "basic"}
      accessible_spot = %{type: "accessible"}
      free_spot = %{type: "free"}
      sorted = sort_parking_spots([free_spot, basic_spot, accessible_spot])
      assert sorted == [basic_spot, accessible_spot, free_spot]
    end
  end

  describe "aggregate_routes/1" do
    test "All green line routes are aggregated" do
      e_line = %{name: "Green-E"}
      d_line = %{name: "Green-D"}
      c_line = %{name: "Green-C"}
      orange_line = %{name: "Orange"}
      line_list = [e_line, d_line, c_line, orange_line]
      green_count = line_list |> aggregate_routes |> Enum.filter(&(&1.name == "Green")) |> Enum.count

      assert green_count == 1
      assert Enum.count(aggregate_routes(line_list)) == 2
    end
  end

  describe "schedule_display_time/2" do
    @time ~N[2017-01-01T22:30:00]
    test "returns difference in minutes when difference is less than 60" do
      diff = @time
      |> Timex.shift(minutes: 10)
      |> schedule_display_time(@time)
      assert diff == "10 mins"
    end

    test "returns formatted time when difference is greater than 60" do
      two_hours_later = Timex.shift(@time, hours: 2)
      diff = schedule_display_time(two_hours_later, @time)
      assert diff == "12:30AM"
    end
  end

  describe "center_query/1" do
    test "returns a marker at the stop if it only has buses" do
      stop = %Stop{id: "2438", latitude: "42.37497", longitude: "-71.102529"}
      assert center_query(stop) == [markers: "42.37497,-71.102529"]
    end

    test "returns the location of the stop as the map center if it serves other modes" do
      stop = %Stop{id: "place-sstat", latitude: "42.352271", longitude: "-71.055242"}
      assert center_query(stop) == [markers: location(stop)]
    end
  end

  describe "fare_surcharge?/1" do
    test "returns true for South, North, and Back Bay stations" do
      for stop_id <- ["place-bbsta", "place-north", "place-sstat"] do
        assert fare_surcharge?(%Stop{id: stop_id})
      end
    end
  end

  describe "info_tab_name/1" do
    test "is stop info when given a bus line" do
      grouped_routes = [bus: [%Routes.Route{direction_names: %{0 => "Outbound", 1 => "Inbound"},
        id: "742", key_route?: true, name: "SL2", type: 3}]]

      assert info_tab_name(grouped_routes) == "Stop Info"
    end

    test "is station info when given any other line" do
      grouped_routes = [
        bus: [%Routes.Route{direction_names: %{0 => "Outbound", 1 => "Inbound"},
          id: "742", key_route?: true, name: "SL2", type: 3}],
        subway: [%Routes.Route{direction_names: %{0 => "Outbound", 1 => "Inbound"},
          id: "Red", key_route?: true, name: "Red", type: 1}]
      ]

      assert info_tab_name(grouped_routes) == "Station Info"
    end
  end

  def do_safe_to_string(elements) when is_list(elements) do
    elements
    |> Enum.map(&Phoenix.HTML.safe_to_string/1)
    |> Enum.join("")
  end
  def do_safe_to_string(string) when is_binary(string), do: string
  def do_safe_to_string(element), do: Phoenix.HTML.safe_to_string(element)
end
