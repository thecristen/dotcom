defmodule Stops.Nearby do
  @doc """

  Returns a list of %Stops.Stop{} around the given latitude/longitude.

  The algorithm should return 12 or fewer results:

  * Return 4 nearest CR or Subway stops
  ** for CR use 50 mile radius
  ** for subway - 30 mile radius
  ** return at least 1 CR stop and 1 Subway stop
  * Return all Bus stops with 1 mi radius
  ** limit to 2 stops per line-direction
  * Return Subway stops in 5 mi radius
  """

  @spec nearby(number, number) :: [Stops.Stop.t]
  def nearby(latitude, longitude) when is_number(latitude) and is_number(longitude) do
    commuter_rail_stops = V3Api.Stops.all(latitude: latitude, longitude: longitude, radius: 1, route_type: 2)
    subway_stops = V3Api.Stops.all(latitude: latitude, longitude: longitude, radius: 0.6, route_type: "0,1")
    bus_stops = V3Api.Stops.all(latitude: latitude, longitude: longitude, radius: 0.02, route_type: 3)
    gather_stops(latitude, longitude, commuter_rail_stops, subway_stops, bus_stops)
  end

  @doc """

  Given a list of commuter rail, subway, and bus stops, organize them
  according to the algorithm.

  """
  def gather_stops(latitude, longitude, commuter_rail, subway, bus) do
    []
  end
end
