defmodule Algolia.MockStopsRepo do
  def by_route_type({1, []}) do
    [get("place-subway")]
  end
  def by_route_type({0, []}) do
    [get("place-greenline")]
  end
  def by_route_type({2, []}) do
    [get("place-commuter-rail")]
  end
  def by_route_type({3, []}) do
    []
  end
  def by_route_type({4, []}) do
    [get("place-ferry")]
  end

  def get("place-subway") do
    %Stops.Stop{
      accessibility: ["accessible", "elevator", "tty_phone", "escalator_up"],
      id: "place-subway",
      latitude: 42.352271,
      longitude: -71.055242,
      name: "Subway Station"
    }
  end
  def get("place-greenline") do
    %Stops.Stop{
      id: "place-greenline",
      accessibility: ["accessible", "mobile_lift"],
      latitude: 42.336142, longitude: -71.149326,
      name: "Green Line Stop"
    }
  end
  def get("place-commuter-rail") do
    %Stops.Stop{
      accessibility: ["accessible"],
      id: "place-commuter-rail",
      latitude: 42.460574,
      longitude: -71.457804,
      name: "Commuter Rail Stop",
      parking_lots: [
        %Stops.Stop.ParkingLot{
          manager: %Stops.Stop.Manager{email: nil, name: "Town of Acton"},
          spots: [%Stops.Stop.Parking{spots: 287, type: "basic"}],
        }
      ]
    }
  end
  def get("place-ferry") do
    %Stops.Stop{
      id: "place-ferry", name: "Ferry Stop",
      accessibility: ["accessible", "ramp"],
      latitude: 42.303251,
      longitude: -70.920215
    }
  end
end
