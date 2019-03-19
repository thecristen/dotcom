defmodule SiteWeb.StopV1ViewTest do
  @moduledoc false
  import SiteWeb.StopV1View
  import Phoenix.HTML, only: [safe_to_string: 1]
  alias Phoenix.HTML
  alias PredictedSchedule.Display
  alias Predictions.Prediction
  alias Routes.Route
  alias Schedules.Schedule
  alias Stops.Stop
  use SiteWeb.ConnCase, async: true

  describe "template_for_tab/1" do
    test "correct template for selected tab" do
      assert template_for_tab(nil) == "_info.html"
      assert template_for_tab("info") == "_info.html"
      assert template_for_tab("departures") == "_departures.html"
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
    @no_accessible_feature %Stop{id: "north", name: "test", accessibility: []}
    @no_accessible_with_feature %Stop{name: "name", accessibility: ["mini_high"]}
    @only_accessible_feature %Stop{name: "test", accessibility: ["accessible"]}
    @many_feature %Stop{name: "test", accessibility: ["accessible", "ramp", "elevator"]}
    @unknown_accessibly %Stop{id: "44", name: "44", accessibility: ["unknown"]}
    @lechmere %Stop{id: "place-lech", name: "Lechmere", accessibility: ["accessible"]}
    @brookline_hills %Stop{
      id: "place-brkhl",
      name: "Brookline Hills",
      accessibility: ["accessible"]
    }
    @newton_highlands %Stop{
      id: "place-newtn",
      name: "Newton Highlands",
      accessibility: ["accessible"]
    }
    @ashmont %Stop{id: "place-asmnl", name: "Ashmont", accessibility: ["accessible", "ramp"]}

    test "Accessibility description reflects features" do
      has_text?(
        accessibility_info(@unknown_accessibly, []),
        "Minor to moderate accessibility barriers exist"
      )

      has_text?(
        accessibility_info(@no_accessible_feature, []),
        "Significant accessibility barriers exist"
      )

      has_text?(
        accessibility_info(@no_accessible_with_feature, []),
        "Significant accessibility barriers exist"
      )

      has_text?(accessibility_info(@only_accessible_feature, []), "is accessible")
      has_text?(accessibility_info(@many_feature, []), "has the following")
    end

    test "Accessibility description only has extra information for bus routes" do
      has_text?(
        accessibility_info(@unknown_accessibly, [:bus]),
        "Bus operator may need to relocate bus for safe boarding and exiting"
      )

      no_text?(
        accessibility_info(@unknown_accessibly, []),
        "Bus operator may need to relocate bus for safe boarding and exiting"
      )

      has_text?(
        accessibility_info(@no_accessible_feature, [:bus]),
        "Customers using wheeled mobility devices may need to board at street level"
      )

      no_text?(
        accessibility_info(@no_accessible_feature, []),
        "Customers using wheeled mobility devices may need to board at street level"
      )
    end

    test "Contact link only appears for stops with accessibility features" do
      text = "Report an elevator, escalator, or other accessibility issue."
      has_text?(accessibility_info(@many_feature, []), text)
      has_text?(accessibility_info(@no_accessible_with_feature, []), text)
      no_text?(accessibility_info(@only_accessible_feature, []), text)
      no_text?(accessibility_info(@no_accessible_feature, []), text)
      no_text?(accessibility_info(@unknown_accessibly, []), text)
    end

    test "Lechemre has special accessibility text" do
      has_text?(
        accessibility_info(@lechmere, [:subway]),
        "Significant accessibility barriers exist at Lechmere, but customers can board/exit the train using a mobile lift."
      )
    end

    test "Newton Highlands has special accessibility text" do
      has_text?(
        accessibility_info(@newton_highlands, [:subway]),
        "Significant accessibility barriers exist at Newton Highlands, but customers can board/exit the train using a mobile lift."
      )
    end

    test "Brookline Hills has special accessibility text" do
      has_text?(
        accessibility_info(@brookline_hills, [:subway]),
        "Significant accessibility barriers exist at Brookline Hills, but customers can board/exit the train using a mobile lift."
      )
    end

    test "Ashmont has special accessibility text" do
      has_text?(
        accessibility_info(@ashmont, [:subway]),
        "Significant accessibility barriers exist at Ashmont, but customers can board/exit the Mattapan Trolley using a mobile lift."
      )
    end

    defp has_text?(unsafe, text) do
      safe =
        unsafe
        |> HTML.html_escape()
        |> HTML.safe_to_string()

      assert safe =~ text
    end

    defp no_text?(unsafe, text) do
      safe =
        unsafe
        |> HTML.html_escape()
        |> HTML.safe_to_string()

      refute safe =~ text
    end
  end

  describe "pretty_accessibility/1" do
    test "formats non-standard accessibility fields" do
      assert pretty_accessibility("tty_phone") == ["TTY Phone"]
      assert pretty_accessibility("escalator_both") == ["Escalator (up and down)"]
      assert pretty_accessibility("escalator_up") == ["Escalator (up only)"]
      assert pretty_accessibility("escalator_down") == ["Escalator (down only)"]
      assert pretty_accessibility("ramp") == ["Long ramp"]

      assert pretty_accessibility("fully_elevated_platform") == [
               "Full high level platform to provide level boarding to every car in a train set"
             ]

      assert pretty_accessibility("elevated_subplatform") == [
               "Mini high level platform to provide level boarding to certain cars in a train set"
             ]
    end

    test "For all other fields, separates underscore and capitalizes first word" do
      assert pretty_accessibility("elevator_issues") == ["Elevator issues"]
      assert pretty_accessibility("down_escalator_repair_work") == ["Down escalator repair work"]
    end

    test "ignores unknown and accessible features" do
      assert pretty_accessibility("unknown") == []
      assert pretty_accessibility("accessible") == []
    end
  end

  describe "location/1" do
    test "returns an encoded address if lat/lng is missing" do
      stop = %Stop{
        id: "place-sstat",
        latitude: nil,
        longitude: nil,
        address: "10 Park Plaza, Boston, MA"
      }

      assert location(stop) == "10%20Park%20Plaza%2C%20Boston%2C%20MA"
    end

    test "returns lat/lng as a string if lat/lng is available" do
      stop = %Stop{id: "2438", latitude: 42.37497, longitude: -71.102529}
      assert location(stop) == "#{stop.latitude},#{stop.longitude}"
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
      grouped_routes = [
        bus: [
          %Route{
            direction_names: %{0 => "Outbound", 1 => "Inbound"},
            id: "742",
            description: :rapid_transit,
            name: "SL2",
            type: 3
          }
        ]
      ]

      assert info_tab_name(grouped_routes) == "Stop Info"
    end

    test "is station info when given any other line" do
      grouped_routes = [
        bus: [
          %Route{
            direction_names: %{0 => "Outbound", 1 => "Inbound"},
            id: "742",
            description: :rapid_transit,
            name: "SL2",
            type: 3
          }
        ],
        subway: [
          %Route{
            direction_names: %{0 => "Outbound", 1 => "Inbound"},
            id: "Red",
            description: :rapid_transit,
            name: "Red",
            type: 1
          }
        ]
      ]

      assert info_tab_name(grouped_routes) == "Station Info"
    end
  end

  describe "time_differences/2" do
    test "returns a list of rendered time differences" do
      date_time = ~N[2017-01-01T11:00:00]
      ps = %PredictedSchedule{schedule: %Schedule{time: ~N[2017-01-01T12:00:00]}}

      assert time_differences([ps], date_time) ==
               [Display.time_difference(ps, date_time)]
    end

    test "time differences are in order from smallest to largest" do
      now = Util.now()

      schedules = [
        %PredictedSchedule{schedule: %Schedule{time: Timex.shift(now, minutes: 3)}},
        %PredictedSchedule{prediction: %Prediction{time: Timex.shift(now, minutes: 1)}},
        %PredictedSchedule{schedule: %Schedule{time: Timex.shift(now, minutes: 5)}}
      ]

      assert [one_min_live, three_mins, five_mins] = time_differences(schedules, now)
      assert safe_to_string(one_min_live) =~ "1 min"
      assert safe_to_string(one_min_live) =~ "icon-realtime"
      assert three_mins == ["3", " ", "min"]
      assert five_mins == ["5", " ", "min"]
    end

    test "sorts status predictions from closest to furthest" do
      date_time = ~N[2017-01-01T00:00:00]

      schedules =
        Enum.shuffle([
          %PredictedSchedule{prediction: %Prediction{status: "Boarding"}},
          %PredictedSchedule{prediction: %Prediction{status: "Approaching"}},
          %PredictedSchedule{prediction: %Prediction{status: "1 stop away"}},
          %PredictedSchedule{prediction: %Prediction{status: "2 stops away"}}
        ])

      assert [board, approach, one_stop] = time_differences(schedules, date_time)
      assert safe_to_string(board) =~ "Boarding"
      assert safe_to_string(approach) =~ "Approaching"
      assert safe_to_string(one_stop) =~ "1 stop away"
    end

    test "filters out predicted schedules we could not render" do
      date_time = ~N[2017-01-01T11:00:00]

      predicted_schedules = [
        %PredictedSchedule{}
      ]

      assert time_differences(predicted_schedules, date_time) == []
    end

    test "does not return a combination of stops away amd time" do
      now = Util.now()
      date_time = ~N[2017-01-01T00:00:00]

      schedules = [
        %PredictedSchedule{prediction: %Prediction{status: "Boarding"}},
        %PredictedSchedule{prediction: %Prediction{status: "Approaching"}},
        %PredictedSchedule{prediction: %Prediction{time: Timex.shift(now, minutes: 5)}}
      ]

      assert [board, approach] = time_differences(schedules, date_time)
      assert safe_to_string(board) =~ "Boarding"
      assert safe_to_string(approach) =~ "Approaching"
    end
  end

  @high_priority_alerts [
    %Alerts.Alert{
      active_period: [{~N[2017-04-12T20:00:00], ~N[2017-05-12T20:00:00]}],
      description: "description",
      effect: :delay,
      header: "header",
      id: "1",
      lifecycle: :ongoing,
      priority: :high
    }
  ]

  @low_priority_alerts [
    %Alerts.Alert{
      active_period: [{~N[2017-04-12T20:00:00], ~N[2017-05-12T20:00:00]}],
      description: "description",
      effect: :access_issue,
      header: "header",
      id: "1",
      priority: :low
    }
  ]

  describe "has_alerts?/2" do
    informed_entity = %Alerts.InformedEntity{
      direction_id: 1,
      route: "556",
      route_type: nil,
      stop: nil,
      trip: nil
    }

    assert !has_alerts?(@high_priority_alerts, informed_entity)
  end

  describe "render_alerts/4" do
    test "displays an alert" do
      response =
        render_alerts(
          @high_priority_alerts,
          ~D[2017-05-11],
          %Stop{id: "2438"},
          priority_filter: :high
        )

      assert safe_to_string(response) =~ "c-alert-item"
    end

    test "does not display an alert" do
      response =
        render_alerts(
          @low_priority_alerts,
          ~D[2017-05-11],
          %Stop{id: "2438"},
          priority_filter: :high
        )

      assert response == ""
    end
  end

  describe "feature_icons/1" do
    test "returns list of featured icons" do
      [red_icon, access_icon | _] = feature_icons(%DetailedStop{features: [:red_line, :access]})
      assert safe_to_string(red_icon) =~ "icon-red-line"
      assert safe_to_string(access_icon) =~ "icon-access"
    end
  end

  def safe_or_list_to_string(list) when is_list(list) do
    Enum.map(list, &safe_or_list_to_string/1)
  end

  def safe_or_list_to_string({:safe, _} = safe) do
    safe_to_string(safe)
  end

  def header_mode_to_string(io) do
    io
    |> Enum.flat_map(&safe_or_list_to_string/1)
    |> IO.iodata_to_binary()
  end

  describe "render_header_modes/2" do
    test "renders separate icon and mode pill for subway lines" do
      grouped_routes = [
        subway: [
          %Route{id: "Red", type: 1, name: "Red Line"},
          %Route{id: "Green-B", type: 0, name: "Green Line B"},
          %Route{id: "Green-C", type: 0, name: "Green Line C"},
          %Route{id: "Green-D", type: 0, name: "Green Line D"},
          %Route{id: "Green-E", type: 0, name: "Green Line E"}
        ]
      ]

      rendered = render_header_modes(%Stop{id: "stop"}, grouped_routes, nil)
      assert [subway_io, [], [], []] = rendered
      subway = header_mode_to_string(subway_io)

      assert Floki.attribute(subway, "href") == [
               "/stops/stop?tab=departures#subway-schedule",
               "/stops/stop?tab=departures#subway-schedule",
               "/stops/stop?tab=departures#subway-schedule",
               "/stops/stop?tab=departures#subway-schedule",
               "/stops/stop?tab=departures#subway-schedule",
               "/stops/stop?tab=departures#subway-schedule"
             ]

      assert [_] = Floki.find(subway, ".c-svg__icon-red-line-default")
      assert Floki.text(subway) =~ "Red Line"
      assert [_] = Floki.find(subway, ".c-svg__icon-green-line-default")
      assert Floki.text(subway) =~ "Green Line"

      for branch <- ["b", "c", "d", "e"] do
        assert [_] = Floki.find(subway, ".c-svg__icon-green-line-#{branch}-default")
        refute Floki.text(subway) =~ "Green Line " <> String.upcase(branch)
      end
    end

    test "renders one icon and pill for ferry" do
      grouped_routes = [
        ferry: [
          %Route{id: "Boat-Hingham", type: 4},
          %Route{id: "Boat-Hull", type: 4}
        ]
      ]

      rendered = render_header_modes(%Stop{id: "stop"}, grouped_routes, nil)
      assert [[], ferry_io, [], []] = rendered
      ferry = header_mode_to_string(ferry_io)
      assert [_] = Floki.find(ferry, ".c-svg__icon-mode-ferry-default")
      assert [_] = Floki.find(ferry, ".station__header-description")
      assert Floki.attribute(ferry, "href") == ["/stops/stop?tab=departures#ferry-schedule"]
    end

    test "renders one icon and pill for commuter rail, and renders zone" do
      grouped_routes = [
        commuter_rail: [
          %Route{id: "CR-Fitchburg", type: 2},
          %Route{id: "CR-Lowell", type: 2}
        ]
      ]

      rendered = render_header_modes(%Stop{id: "stop"}, grouped_routes, 2)
      assert [[], [], cr_io, []] = rendered
      cr = header_mode_to_string(cr_io)
      assert [_] = Floki.find(cr, ".c-svg__icon-mode-commuter-rail-default")
      assert [_] = Floki.find(cr, ".station__header-description")
      assert [_] = Floki.find(cr, ".c-icon__cr-zone")

      assert Floki.attribute(cr, "href") == [
               "/stops/stop?tab=departures#commuter-rail-schedule",
               "/stops/stop?tab=info#commuter-fares"
             ]
    end

    test "renders CR with no zone if zone not assigned" do
      grouped_routes = [
        commuter_rail: [
          %Route{id: "CR-Fitchburg", type: 2},
          %Route{id: "CR-Lowell", type: 2}
        ]
      ]

      rendered = render_header_modes(%Stop{id: "stop"}, grouped_routes, nil)
      assert [[], [], cr_io, []] = rendered
      cr = header_mode_to_string(cr_io)
      assert [_] = Floki.find(cr, ".c-svg__icon-mode-commuter-rail-default")
      assert [_] = Floki.find(cr, ".station__header-description")
      assert Floki.find(cr, ".c-icon__cr-zone") == []
      assert Floki.attribute(cr, "href") == ["/stops/stop?tab=departures#commuter-rail-schedule"]
    end

    test "renders one icon with no pill for bus lines" do
      grouped_routes = [
        bus: [
          %Route{id: "77", type: 3},
          %Route{id: "86", type: 3}
        ]
      ]

      rendered = render_header_modes(%Stop{id: "stop"}, grouped_routes, nil)
      assert [[], [], [], bus_io] = rendered
      bus = header_mode_to_string(bus_io)
      assert [_] = Floki.find(bus, ".c-svg__icon-mode-bus-default")
      assert Floki.find(bus, ".station__header-description") == []
      assert Floki.attribute(bus, "href") == ["/stops/stop?tab=departures#bus-schedule"]
    end
  end

  describe "_info.html" do
    test "Ferry Fare link preselects origin", %{conn: conn} do
      output =
        render(
          "_info.html",
          alerts: [],
          fare_name: "The Iron Price",
          date: ~D[2017-05-11],
          stop: %Stop{name: "Iron Island", id: "IronIsland"},
          grouped_routes: [{:ferry}],
          fare_types: [:ferry],
          fare_sales_locations: [],
          terminal_stations: %{4 => ""},
          conn: conn
        )

      assert safe_to_string(output) =~ "/fares/ferry?origin=IronIsland"
    end

    test "Can render multiple fares types", %{conn: conn} do
      output =
        render(
          "_info.html",
          alerts: [],
          fare_name: "The Iron Price",
          date: ~D[2017-05-11],
          stop: %Stop{name: "My Stop", id: "MyStop"},
          grouped_routes: [{:bus}, {:subway}],
          fare_types: [:bus, :subway],
          fare_sales_locations: [],
          terminal_stations: %{4 => ""},
          conn: conn
        )

      assert safe_to_string(output) =~ "Local Bus One-Way"
      assert safe_to_string(output) =~ "Subway One-Way"
    end

    test "Does not render fares unless they are in fare_types assign", %{conn: conn} do
      output =
        render(
          "_info.html",
          alerts: [],
          fare_name: "The Iron Price",
          date: ~D[2017-05-11],
          stop: %Stop{name: "My Stop", id: "MyStop"},
          grouped_routes: [{:bus}, {:subway}],
          fare_types: [:subway],
          fare_sales_locations: [],
          terminal_stations: %{4 => ""},
          conn: conn
        )

      refute safe_to_string(output) =~ "Local Bus One-Way"
      assert safe_to_string(output) =~ "Subway One-Way"
    end
  end

  describe "_detailed_stop_list.html" do
    test "renders a list of stops", %{conn: conn} do
      stops = [
        %DetailedStop{stop: %Stop{name: "Alewife", id: "place-alfcl"}},
        %DetailedStop{stop: %Stop{name: "Davis", id: "place-davis"}},
        %DetailedStop{stop: %Stop{name: "Porter", id: "place-porter"}}
      ]

      html =
        "_detailed_stop_list.html"
        |> render(detailed_stops: stops, conn: conn)
        |> safe_to_string()

      assert [alewife, davis, porter] = Floki.find(html, ".stop-btn")
      assert Floki.text(alewife) =~ "Alewife"
      assert Floki.text(davis) =~ "Davis"
      assert Floki.text(porter) =~ "Porter"
    end
  end

  describe "_search_bar.html" do
    test "renders a search bar", %{conn: conn} do
      stops = [
        %DetailedStop{stop: %Stop{name: "Alewife", id: "place-alfcl"}},
        %DetailedStop{stop: %Stop{name: "Davis", id: "place-davis"}},
        %DetailedStop{stop: %Stop{name: "Porter", id: "place-porter"}}
      ]

      html =
        "_search_bar.html"
        |> render(stop_info: stops, conn: conn)
        |> safe_to_string()

      assert [{"div", _, _}] = Floki.find(html, ".c-search-bar")
    end
  end
end
