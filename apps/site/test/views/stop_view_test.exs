defmodule Site.StopViewTest do
  @moduledoc false
  alias Site.StopView
  alias Stops.Stop
  alias Predictions.Prediction
  use Site.ConnCase, async: true

  describe "fare_group/1" do
    test "return correct fare group for all modes" do
      assert StopView.fare_group(:bus) == "bus_subway"
      assert StopView.fare_group(:subway) == "bus_subway"
      assert StopView.fare_group(:commuter_rail) == "commuter_rail"
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

  describe "tab_selected?/2" do
    test "true for the selected tab, false otherwise" do
      assert StopView.tab_selected?("schedule", nil)
      refute StopView.tab_selected?("info", nil)
      refute StopView.tab_selected?("schedule", "info")
      assert StopView.tab_selected?("info", "info")
    end
  end

  describe "show_fares?/1" do
    test "Do not show fare information for Origin stations" do
      north_station = %Stop{id: "place-north"}
      back_bay = %Stop{id: "place-bbsta"}
      salem = %Stop{id: "Salem"}
      westborough = %Stop{id: "Westborough"}

      assert !StopView.show_fares?(north_station)
      assert !StopView.show_fares?(back_bay)
      assert StopView.show_fares?(salem)
      assert StopView.show_fares?(westborough)
    end
  end

  describe "fare_mode/1" do
    test "types are separated as bus, subway or both" do
      assert StopView.fare_mode([:bus, :commuter_rail, :ferry]) == :bus
      assert StopView.fare_mode([:subway, :commuter_rail, :ferry]) == :subway
      assert StopView.fare_mode([:subway, :commuter_rail, :ferry, :bus]) == :bus_subway
    end
  end

  describe "accessibility_info" do
    test "Accessibility description reflects features" do
      no_accessibility = %Stop{name: "test", accessibility: nil}
      no_accessible_feature = %Stop{id: "north", name: "test", accessibility: []}
      only_accessible_feature = %Stop{name: "test", accessibility: ["accessible"]}
      many_feature = %Stop{name: "test", accessibility: ["accessible", "ramp", "elevator"]}
      tag_has_text = fn(tag, text) -> Phoenix.HTML.safe_to_string(Enum.at(tag, 0)) =~ text end

      assert tag_has_text.(StopView.accessibility_info(no_accessibility), "No accessibility")
      assert tag_has_text.(StopView.accessibility_info(no_accessible_feature), "No accessibility")
      assert tag_has_text.(StopView.accessibility_info(only_accessible_feature), "wheeled mobility devices")
      assert tag_has_text.(StopView.accessibility_info(many_feature), "has the following")
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
      diff = now
      |> Timex.shift(minutes: 10)
      |> StopView.schedule_display_time(now)
      assert diff == "10 mins"
    end

    test "returns formatted time when difference is greater than 60" do
      now = Util.now
      time = Timex.shift(now, hours: 2)
      diff = time
      |> StopView.schedule_display_time(now)
      assert diff == time |> formatted_time
    end
  end

  describe "commuter schedules" do
    test "display scheduled time, predicted time, and realtime icon for routes with delays " do
      route_id = "CR-Fairmount"
      direction_id = 1
      trip_id = "CR-Weekday-Fall-16-823"
      now = Util.now
      later = Util.now |> Timex.shift(minutes: 1)
      predictions = [
        %Prediction{trip: %Schedules.Trip{id: trip_id, headsign: "", name: "", direction_id: "1"}, time: later}
      ]
      rendered = route_id
                 |> StopView.render_commuter_departure_time(direction_id, trip_id, now, predictions)
                 |> do_safe_to_string
      assert rendered =~ formatted_time(now)
      assert rendered =~ "fa fa-rss station-schedule-icon"
      assert rendered =~ formatted_time(later)
    end

    test "only display scheduled time for routes without delays" do
      route_id = "CR-Fairmount"
      direction_id = 1
      trip_id = "CR-Weekday-Fall-16-823"
      now = Util.now
      predictions = [
        %Prediction{trip: %Schedules.Trip{id: trip_id, headsign: "", name: "", direction_id: "1"}, time: now}
      ]
      rendered = route_id
                 |> StopView.render_commuter_departure_time(direction_id, trip_id, now, predictions)
                 |> do_safe_to_string
      assert rendered =~ formatted_time(now)
      refute rendered =~ "<s>" <> formatted_time(now)
      refute rendered =~ "fa fa-rss station-schedule-icon"
    end

    test "only display scheduled time if rendered prediction and rendered schedule are the same" do
      route_id = "CR-Fairmount"
      direction_id = 1
      trip_id = "CR-Weekday-Fall-16-823"
      now = Timex.to_datetime {Timex.to_erl(Util.service_date), {14,0,0}}
      later = Timex.shift now, seconds: 45
      predictions = [
        %Prediction{trip: %Schedules.Trip{id: trip_id, headsign: "", name: "", direction_id: "1"}, time: later}
      ]
      rendered = route_id
                 |> StopView.render_commuter_departure_time(direction_id, trip_id, now, predictions)
                 |> do_safe_to_string
      assert rendered =~ formatted_time(now)
      assert rendered =~ formatted_time(later)
      refute rendered =~ "fa fa-rss station-schedule-icon"
    end

    test "do not show commuter rail predictions that are earlier than the scheduled departure" do
      route_id = "CR-Fairmount"
      direction_id = 1
      trip_id = "CR-Weekday-Fall-16-823"
      now = Util.now
      earlier = Timex.shift(now, minutes: -2)
      predictions = [
        %Prediction{trip: %Schedules.Trip{id: trip_id, headsign: "", name: "", direction_id: "1"}, time: earlier}
      ]
      rendered = route_id
                 |> StopView.render_commuter_departure_time(direction_id, trip_id, now, predictions)
                 |> do_safe_to_string
      assert rendered =~ formatted_time(now)
      refute rendered =~ formatted_time(earlier)
      refute rendered =~ "fa fa-rss station-schedule-icon"
    end

    test "show track number when available" do
      trip_id = "CR-Weekday-Fall-16-823"
      rendered = trip_id
      |> StopView.render_commuter_status(
        Util.now, [
          %Prediction{
            trip: %Schedules.Trip{id: trip_id, headsign: "", name: "", direction_id: "1"},
            status: "Now Boarding",
            track: 5}
        ])
      |> do_safe_to_string
      assert rendered =~ "Now Boarding"
      assert rendered =~ "track 5"
    end

    test "shows \"Delayed X min\" when status is nil and train is delayed" do
      now = Util.now
      trip_id = "CR-Weekday-Fall-16-823"
      rendered = trip_id
      |> StopView.render_commuter_status(
        now, [
          %Prediction{
            trip: %Schedules.Trip{id: trip_id, headsign: "", name: "", direction_id: "1"},
            time: Timex.shift(now, minutes: 2)}
        ])
      |> do_safe_to_string
      assert rendered =~ "Delayed"
      assert rendered =~ "2 min"
    end

    test "shows \"On Time\" when status is nil and train is not delayed" do
      now = Util.now
      trip_id = "CR-Weekday-Fall-16-823"
      assert StopView.render_commuter_status(
        trip_id,
        now,
        [%Prediction{trip: %Schedules.Trip{id: trip_id, headsign: "", name: "", direction_id: "1"}, time: now}]
      ) =~ "On Time"
    end
  end

  describe "center_query/1" do
    test "returns a marker at the stop if it only has buses" do
      stop = %Stop{id: "2438", latitude: "42.37497", longitude: "-71.102529"}
      assert Site.StopView.center_query(stop) == [markers: "42.37497,-71.102529"]
    end

    test "returns the location of the stop as the map center if it serves other modes" do
      stop = %Stop{id: "place-sstat", latitude: "42.352271", longitude: "-71.055242"}
      assert Site.StopView.center_query(stop) == [center: Site.StopView.location(stop)]
    end
  end

  describe "fare_surcharge?/1" do
    test "returns true for South, North, and Back Bay stations" do
      for stop_id <- ["place-bbsta", "place-north", "place-sstat"] do
        assert Site.StopView.fare_surcharge?(%Stop{id: stop_id})
      end
    end
  end

  def formatted_time(time), do: time |> Timex.format!("{h12}:{m} {AM}")

  def do_safe_to_string(elements) when is_list(elements) do
    elements
    |> Enum.map(&Phoenix.HTML.safe_to_string/1)
    |> Enum.join("")
  end
  def do_safe_to_string(string) when is_binary(string), do: string
  def do_safe_to_string(element), do: Phoenix.HTML.safe_to_string(element)
end
