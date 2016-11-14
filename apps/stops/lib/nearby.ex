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

  @mile_in_degrees 0.02
  @total 12

  import Stops.Distance

  @spec nearby(Stops.Position.t) :: [Stops.Stop.t]
  def nearby(position) do
    latitude = Stops.Position.latitude(position)
    longitude = Stops.Position.longitude(position)

    commuter_rail_stops = V3Api.Stops.all(latitude: latitude, longitude: longitude, radius: @mile_in_degrees * 50, route_type: 2)
    subway_stops = V3Api.Stops.all(latitude: latitude, longitude: longitude, radius: @mile_in_degrees * 30, route_type: "0,1")
    bus_stops = V3Api.Stops.all(latitude: latitude, longitude: longitude, radius: @mile_in_degrees, route_type: 3)
    gather_stops(position, commuter_rail_stops, subway_stops, bus_stops)
  end

  @doc """

  Given a list of commuter rail, subway, and bus stops, organize them
  according to the algorithm.

  """
  def gather_stops(_, [], [], []) do
    []
  end
  def gather_stops(position, commuter_rail, subway, bus) do
    hub_stations = gather_hub_stations(position, commuter_rail, subway)
    bus = gather_bus_stops(position, bus, hub_stations)

    [hub_stations, bus]
    |> Enum.concat
    |> sort(position)
  end

  defp gather_hub_stations(position, commuter_rail, subway) do
    {first_cr, sorted_commuter_rail} = closest_and_rest(commuter_rail, position)
    {first_subway, sorted_subway} = closest_and_rest(subway, position)

    initial = (first_cr ++ first_subway) |> Enum.uniq
    rest = (sorted_commuter_rail ++ sorted_subway) |> Enum.uniq

    initial ++ closest(rest, position, 4 - length(initial))
  end

  defp gather_bus_stops(position, bus, existing) do
    bus
    |> Enum.reject(&(&1 in existing))
    |> closest(position, @total - length(existing))
  end

  # Returns the closest item (in a list) as well as the rest of the list.  In
  # the case of an empty initial list, returns a tuple of two empty lists.
  # The first list represents a kind of Maybe: [item] :: Just item and [] :: Nothing
  @spec closest_and_rest([Position.t], Position.t) :: {[Position.t], [Position.t]}
  defp closest_and_rest([], _) do
    {[], []}
  end
  defp closest_and_rest(items, position) do
    [first | rest] = sort(items, position)

    {[first], rest}
  end
end
