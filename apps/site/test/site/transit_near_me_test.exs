defmodule Site.TransitNearMeTest do
  use ExUnit.Case

  alias GoogleMaps.Geocode.Address
  alias Routes.Route
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
  end
end
