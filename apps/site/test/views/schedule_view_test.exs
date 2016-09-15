defmodule Site.ScheduleViewTest do
  @moduledoc false
  use Site.ConnCase, async: true
  alias Site.ScheduleView
  import Phoenix.HTML.Tag, only: [tag: 2]

  @stop %Schedules.Stop{id: "stop_id"}
  @trip %Schedules.Trip{id: "trip_id"}
  @route %Routes.Route{type: 2, id: "route_id"}
  @schedule %Schedules.Schedule{stop: @stop, trip: @trip, route: @route}

  describe "reverse_direction_opts/4" do
    test "reverses direction when the stop exists in the other direction" do
      expected = [trip: "", direction_id: "1", dest: "place-harsq", origin: "place-davis", route: "Red"]
      actual = ScheduleView.reverse_direction_opts("place-harsq", "place-davis", "Red", "1")
      assert Keyword.equal?(expected, actual)
    end

    test "doesn't maintain stops when the stop does not exist in the other direction" do
      expected = [trip: "", direction_id: "1", dest: nil, origin: nil, route: "16"]
      actual = ScheduleView.reverse_direction_opts("111", "2905", "16", "1")
      assert Keyword.equal?(expected, actual)
    end
  end

  describe "hidden_query_params/2" do
    test "creates a hidden tag for each query parameter", %{conn: conn} do
      actual = %{conn | query_params: %{"one" => "value", "two" => "other"}}
      |> ScheduleView.hidden_query_params

      expected = [tag(:input, type: "hidden", name: "one", value: "value"),
                  tag(:input, type: "hidden", name: "two", value: "other")]

      assert expected == actual
    end
  end

  test "translates the type number to a string" do
    assert ScheduleView.header_text(0, "test route") == "test route"
    assert ScheduleView.header_text(3, "2") == "Route 2"
    assert ScheduleView.header_text(1, "Red Line") == "Red Line"
    assert ScheduleView.header_text(2, "Fitchburg Line") == "Fitchburg"
  end

  test "map_icon_link generates a station link on a map icon" do
    station = %Stations.Station{accessibility: ["accessible", "tty_phone", "escalator_up",
       "elevator"], address: "Atlantic Ave & Summer St Boston, MA 02110",
      id: "place-sstat", images: [], latitude: 42.352271, longitude: -71.055242,
      name: "South Station", note: "",
      parking_lots: [%Stations.Station.ParkingLot{average_availability: "",
        manager: %Stations.Station.Manager{email: "boston@propark.com",
         name: "Propark America", phone: "(617) 742-8025",
         website: "www.proparkboston.com"}, name: "", note: "",
        rate: "Variable rates beginning at $4/ 30 minutes.  Overnight maximum of $27/day",
        spots: [%Stations.Station.Parking{manager: nil, note: nil, rate: nil,
          spots: 8, type: "bike"},
         %Stations.Station.Parking{manager: nil, note: nil, rate: nil, spots: 8,
          type: "accessible"},
         %Stations.Station.Parking{manager: nil, note: nil, rate: nil, spots: 226,
          type: "basic"}]}]}
    assert ScheduleView.map_icon_link(station) == {:safe,
            [60, "a", " href=\"/stations/place-sstat\"", 62,
             "<i class=\"fa fa-map-o\" aria-hidden=true></i>", 60, 47, "a", 62]}

  end
end
