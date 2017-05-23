defmodule Site.StopViewTest do
  @moduledoc false
  import Site.StopView
  import Phoenix.HTML, only: [safe_to_string: 1]
  alias Stops.Stop
  alias Routes.Route
  alias Schedules.Schedule
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
      assert template_for_tab(nil) == "_info.html"
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
      e_line = %Route{id: "Green-E"}
      d_line = %Route{id: "Green-D"}
      c_line = %Route{id: "Green-C"}
      orange_line = %Route{id: "Orange"}
      line_list = [e_line, d_line, c_line, orange_line]
      green_count = line_list |> aggregate_routes |> Enum.filter(&(&1.id == "Green")) |> Enum.count

      assert green_count == 1
      assert Enum.count(aggregate_routes(line_list)) == 2
    end

    test "Mattapan is not aggregated" do
      orange_line = %Route{id: "Orange"}
      red_line = %Route{id: "Red"}
      mattapan = %Route{id: "Mattapan"}
      routes = [orange_line, red_line, mattapan] |> aggregate_routes |> Enum.map(& &1.id)
      assert Enum.count(routes) == 3
      assert "Red" in routes
      assert "Mattapan" in routes
    end
  end

  describe "normalize_route/2" do
    test "Green routes are normalized to Green" do
      green_e = %Route{id: "Green-E"}
      green_b = %Route{id: "Green-B"}
      green_c = %Route{id: "Green-C"}
      green_d = %Route{id: "Green-D"}
      for route_id <- Enum.map([green_e, green_b, green_c, green_d], &normalize_route(&1)) do
        assert route_id == "Green"
      end
    end

    test "Mattapan is kept as mattapan" do
      mattapan = %Route{id: "Mattapan"}
      assert normalize_route(mattapan) == "Mattapan"
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
      grouped_routes = [bus: [%Route{direction_names: %{0 => "Outbound", 1 => "Inbound"},
        id: "742", key_route?: true, name: "SL2", type: 3}]]

      assert info_tab_name(grouped_routes) == "Stop Info"
    end

    test "is station info when given any other line" do
      grouped_routes = [
        bus: [%Route{direction_names: %{0 => "Outbound", 1 => "Inbound"},
          id: "742", key_route?: true, name: "SL2", type: 3}],
        subway: [%Route{direction_names: %{0 => "Outbound", 1 => "Inbound"},
          id: "Red", key_route?: true, name: "Red", type: 1}]
      ]

      assert info_tab_name(grouped_routes) == "Station Info"
    end
  end

  describe "time_differences/2" do
    test "returns a list of rendered time differences" do
      date_time = ~N[2017-01-01T11:00:00]
      ps = %PredictedSchedule{schedule: %Schedule{time: ~N[2017-01-01T12:00:00]}}
      assert time_differences([ps], date_time) ==
        [PredictedSchedule.Display.time_difference(ps, date_time)]
    end

    test "filters out predicted schedules we could not render" do
      date_time = ~N[2017-01-01T11:00:00]
      ps = %PredictedSchedule{}
      assert time_differences([ps], date_time) == []
    end
  end

  @alerts [%Alerts.Alert{active_period: [{~N[2017-04-12T20:00:00], ~N[2017-05-12T20:00:00]}], description: "description", effect_name: "Access Issue", header: "header", id: "1"}]
  
  describe "has_alerts?/3" do
    date = ~D[2017-05-11]
    informed_entity = %Alerts.InformedEntity{direction_id: 1, route: "556", route_type: nil, stop: nil, trip: nil}
    assert !has_alerts?(@alerts, date, informed_entity)
  end

  describe "render_alerts/3" do
    response = render_alerts(@alerts, ~D[2017-05-11], %Stop{id: "2438"})
    assert safe_to_string(response) =~ "alert-list-item"
  end

  describe "feature_icons/1" do
    test "returns list of featured icons" do
      [red_icon, access_icon | _] = feature_icons(%DetailedStop{features: [:red_line, :access]})
      assert safe_to_string(red_icon) =~ "icon-red-line"
      assert safe_to_string(access_icon) =~ "icon-access"
    end
  end
end
