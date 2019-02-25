defmodule Site.TransitNearMeTest do
  use ExUnit.Case

  alias GoogleMaps.Geocode.Address
  alias Predictions.Prediction
  alias Routes.Route
  alias Schedules.{Schedule, Trip}
  alias Site.TransitNearMe
  alias Stops.Stop

  @address %Address{
    latitude: 42.351,
    longitude: -71.066,
    formatted: "10 Park Plaza, Boston, MA, 02116"
  }

  @date Util.service_date()

  describe "build/2" do
    test "builds a set of data for a location" do
      data = TransitNearMe.build(@address, date: @date, now: Util.now())

      assert %TransitNearMe{} = data

      assert data.location == @address

      assert Enum.map(data.stops, & &1.name) == [
               "Stuart St @ Charles St S",
               "Charles St S @ Park Plaza",
               "285 Tremont St",
               "Tufts Medical Center",
               "Tremont St @ Charles St S",
               "Boylston",
               "Kneeland St @ Washington St",
               "Tremont St @ Boylston Station",
               "Washington St @ Essex St",
               "Washington St @ Essex St",
               "Park Street",
               "South Station"
             ]

      ordered_distances = Enum.map(data.stops, &Map.fetch!(data.distances, &1.id))

      # stops are in order of distance from location
      assert ordered_distances == Enum.sort(ordered_distances)
    end
  end

  describe "routes_for_stop/2" do
    test "returns a list of routes that visit a stop" do
      data = TransitNearMe.build(@address, date: @date, now: Util.now())
      routes = TransitNearMe.routes_for_stop(data, "place-pktrm")

      assert Enum.map(routes, & &1.name) == [
               "Red Line",
               "Green Line B",
               "Green Line C",
               "Green Line E",
               "Green Line D"
             ]
    end
  end

  describe "schedules_for_routes/1" do
    test "returns a list of custom route structs" do
      data = TransitNearMe.build(@address, date: @date, now: Util.now())

      routes = TransitNearMe.schedules_for_routes(data)

      [%{id: closest_stop} | _] = data.stops

      assert [route | _] = routes

      assert [:stops | %Route{} |> Map.from_struct() |> Map.keys()] |> Enum.sort() ==
               route |> Map.keys() |> Enum.sort()

      assert %{stops: [stop | _]} = route

      assert stop.id == closest_stop

      assert [:distance, :directions, :href | %Stop{} |> Map.from_struct() |> Map.keys()]
             |> Enum.sort() == stop |> Map.keys() |> Enum.sort()

      assert stop.distance == "238 ft"

      assert %{directions: [direction | _]} = stop

      assert direction.direction_id in [0, 1]

      assert Map.keys(direction) == [:direction_id, :headsigns]

      assert %{headsigns: [headsign | _]} = direction

      assert Map.keys(headsign) == [:name, :times, :train_number]

      assert length(headsign.times) <= 2

      assert %{times: [time | _]} = headsign

      assert Map.keys(time) == [:prediction, :scheduled_time]

      assert %{scheduled_time: scheduled_time, prediction: prediction} = time

      assert {:ok, _} = Timex.parse(Enum.join(scheduled_time), "{h12}:{m} {AM}")

      if prediction do
        assert Map.keys(prediction) == [:status, :time, :track]
      end
    end

    test "filters out bus routes which aren't coming in the next 24 hours" do
      time_too_far_in_future = Timex.shift(Util.now(), hours: 25)

      data = %TransitNearMe{
        location: @address,
        stops: [
          %Stops.Stop{
            accessibility: ["accessible"],
            address: nil,
            closed_stop_info: nil,
            has_charlie_card_vendor?: false,
            has_fare_machine?: false,
            id: "6542",
            is_child?: false,
            latitude: 42.350845,
            longitude: -71.062868,
            name: "Kneeland St @ Washington St",
            note: nil,
            parking_lots: [],
            station?: false
          },
          %Stops.Stop{
            accessibility: ["accessible", "escalator_both", "elevator", "fully_elevated_platform"],
            address: "700 Atlantic Ave, Boston, MA 02110",
            closed_stop_info: nil,
            has_charlie_card_vendor?: false,
            has_fare_machine?: true,
            id: "place-sstat",
            is_child?: false,
            latitude: 42.352271,
            longitude: -71.055242,
            name: "South Station",
            note: nil,
            parking_lots: [
              %Stops.Stop.ParkingLot{
                address: nil,
                capacity: %Stops.Stop.ParkingLot.Capacity{
                  accessible: 4,
                  total: 210,
                  type: "Garage"
                },
                latitude: 42.349838,
                longitude: -71.055963,
                manager: %Stops.Stop.ParkingLot.Manager{
                  contact: "ProPark",
                  name: "ProPark",
                  phone: "617-345-0202",
                  url: "https://www.propark.com/propark-locator2/south-station-garage/"
                },
                name: "South Station Bus Terminal Garage",
                note: nil,
                payment: %Stops.Stop.ParkingLot.Payment{
                  daily_rate:
                    "Hourly: 30 min: $5, 1 hr: $10, 1.5 hrs: $15, 2 hrs: $20, 2.5 hrs: $25, 3+ hrs: $30 | Daily Max: $30 | Early Bird (in by 8:30 AM, out by 6 PM): $26 | Nights/Weekends: $10",
                  methods: ["Credit/Debit Card", "Cash"],
                  mobile_app: nil,
                  monthly_rate: "$150 regular, $445 overnight"
                },
                utilization: nil
              }
            ],
            station?: true
          }
        ],
        distances: %{
          "6542" => 0.16028527858228725,
          "place-sstat" => 0.5562971500164419
        },
        schedules: %{
          "6542" => [
            %Schedules.Schedule{
              early_departure?: true,
              flag?: false,
              pickup_type: 0,
              route: %Routes.Route{
                custom_route?: false,
                description: :local_bus,
                direction_destinations: %{0 => "Roberts", 1 => "Downtown Boston"},
                direction_names: %{0 => "Outbound", 1 => "Inbound"},
                id: "553",
                long_name: "Roberts - Downtown Boston",
                name: "553",
                type: 3
              },
              stop: %Stops.Stop{
                accessibility: ["accessible"],
                address: nil,
                closed_stop_info: nil,
                has_charlie_card_vendor?: false,
                has_fare_machine?: false,
                id: "6542",
                is_child?: false,
                latitude: 42.350845,
                longitude: -71.062868,
                name: "Kneeland St @ Washington St",
                note: nil,
                parking_lots: [],
                station?: false
              },
              stop_sequence: 32,
              time: time_too_far_in_future,
              trip: %Schedules.Trip{
                bikes_allowed?: true,
                direction_id: 1,
                headsign: "Downtown via Copley (Express)",
                id: "39426144",
                name: "",
                shape_id: "5530078"
              }
            }
          ],
          "place-sstat" => [
            %Schedules.Schedule{
              early_departure?: true,
              flag?: false,
              pickup_type: 0,
              route: %Routes.Route{
                custom_route?: false,
                description: :rapid_transit,
                direction_destinations: %{0 => "Ashmont/Braintree", 1 => "Alewife"},
                direction_names: %{0 => "South", 1 => "North"},
                id: "Red",
                long_name: "Red Line",
                name: "Red Line",
                type: 1
              },
              stop: %Stops.Stop{
                accessibility: ["accessible"],
                address: nil,
                closed_stop_info: nil,
                has_charlie_card_vendor?: false,
                has_fare_machine?: false,
                id: "place-sstat",
                is_child?: true,
                latitude: 42.352271,
                longitude: -71.055242,
                name: "South Station",
                note: nil,
                parking_lots: [],
                station?: false
              },
              stop_sequence: 90,
              time: time_too_far_in_future,
              trip: %Schedules.Trip{
                bikes_allowed?: false,
                direction_id: 0,
                headsign: "Ashmont",
                id: "38899812-21:00-LL",
                name: "",
                shape_id: "931_0009"
              }
            }
          ]
        }
      }

      routes = TransitNearMe.schedules_for_routes(data)

      # Filter applies to bus routes…
      refute Enum.find(routes, &(&1.id == "553"))
      # …but not other route types
      assert Enum.find(routes, &(&1.id == "Red"))
    end

    test "sorts directions and headsigns within stops" do
      route = %Route{
        id: "subway",
        type: 1,
        direction_destinations: %{0 => "Direction 0", 1 => "Direction 1"}
      }

      stop = %Stop{
        id: "stop",
        latitude: @address.latitude + 0.01,
        longitude: @address.longitude - 0.01
      }

      trips = [
        %Trip{
          id: "trip-0",
          headsign: "Headsign B",
          direction_id: 0,
          shape_id: "shape-1"
        },
        %Trip{
          id: "trip-1",
          headsign: "Headsign A",
          direction_id: 0,
          shape_id: "shape-2"
        },
        %Trip{
          id: "trip-2",
          headsign: "Headsign B",
          direction_id: 0,
          shape_id: "shape-1"
        }
      ]

      base_schedule = %Schedule{stop: stop, route: route}

      pm_12_00 = DateTime.from_naive!(~N[2019-02-19T12:00:00], "Etc/UTC")
      pm_12_01 = DateTime.from_naive!(~N[2019-02-19T12:01:00], "Etc/UTC")
      pm_12_02 = DateTime.from_naive!(~N[2019-02-19T12:02:00], "Etc/UTC")

      input = %TransitNearMe{
        distances: %{"stop" => 0.1},
        location: @address,
        schedules: %{
          "stop-1" => [
            %{
              base_schedule
              | # Headsign B -- 12:00
                trip: Enum.at(trips, 0),
                time: pm_12_00
            },
            %{
              base_schedule
              | # Headsign A -- 12:01
                trip: Enum.at(trips, 1),
                time: pm_12_01
            },
            %{
              base_schedule
              | # Headsign B -- 12:02
                trip: Enum.at(trips, 2),
                time: pm_12_02
            }
          ]
        },
        stops: [stop]
      }

      stop_repo_fn = fn "stop" -> stop end

      predictions_fn = fn
        trip: "trip-0" -> [%Prediction{time: pm_12_00}]
        trip: "trip-1" -> [%Prediction{time: pm_12_01}]
        trip: "trip-2" -> [%Prediction{time: pm_12_02}]
      end

      output =
        TransitNearMe.schedules_for_routes(
          input,
          predictions_fn: predictions_fn,
          stops_fn: stop_repo_fn
        )

      assert Enum.count(output) === 1
      [%{stops: stops}] = output

      assert Enum.count(stops) === 1
      [stop] = stops

      assert Enum.count(stop.directions) === 1
      [%{headsigns: headsigns}] = stop.directions

      assert Enum.map(headsigns, fn headsign -> headsign.name end) == [
               "Headsign B",
               "Headsign A"
             ]

      [headsign_b, _headsign_a] = headsigns

      assert [
               %{prediction: %{time: ["12:00", " ", "PM"]}},
               %{prediction: %{time: ["12:02", " ", "PM"]}}
             ] = headsign_b.times
    end
  end

  describe "simple_prediction/2" do
    test "returns nil if no prediction" do
      assert nil == TransitNearMe.simple_prediction(nil, :commuter_rail)
    end

    test "returns up to three keys if a prediction is available" do
      assert %{time: _, track: _, status: _} =
               TransitNearMe.simple_prediction(
                 %Prediction{time: Util.now(), track: 1, status: "On time"},
                 :commuter_rail
               )
    end

    test "returns a AM/PM time for CR" do
      [time, _, am_pm] =
        TransitNearMe.simple_prediction(%Prediction{time: Util.now()}, :commuter_rail).time

      assert time =~ ~r/\d{1,2}:\d\d/
      assert am_pm =~ ~r/(AM|PM)/
    end

    test "returns a time difference for modes other than CR" do
      assert [_, _, "min"] =
               TransitNearMe.simple_prediction(
                 %Prediction{time: Timex.shift(Util.now(), minutes: 5)},
                 :subway
               ).time
    end
  end

  describe "format_min_time/1" do
    test "returns hour greater than 24 between midnight and 3:00am" do
      {:ok, midnight} = DateTime.from_naive(~N[2019-02-22T00:00:00], "Etc/UTC")
      assert midnight.hour === 0
      assert TransitNearMe.format_min_time(midnight) === "24:00"

      {:ok, one_thirty} = DateTime.from_naive(~N[2019-02-22T01:30:00], "Etc/UTC")
      assert one_thirty.hour === 1
      assert TransitNearMe.format_min_time(one_thirty) === "25:30"

      {:ok, two_fifty_nine} = DateTime.from_naive(~N[2019-02-22T02:59:00], "Etc/UTC")
      assert two_fifty_nine.hour === 2
      assert TransitNearMe.format_min_time(two_fifty_nine) === "26:59"

      {:ok, three_am} = DateTime.from_naive(~N[2019-02-22T03:00:00], "Etc/UTC")
      assert three_am.hour === 3
      assert TransitNearMe.format_min_time(three_am) === "03:00"
    end
  end
end
