defmodule ExcludedStops do
  @moduledoc """
  Responsible for determing which, if any, stops should be filtered out of the list of all_stops
  based on origin, route ID, and direction ID.
  """

  @braintree_stops [
    "place-brntn",
    "place-qamnl",
    "place-qnctr",
    "place-wlsta",
    "place-nqncy"
  ]
  @ashmont_stops [
    "place-asmnl",
    "place-smmnl",
    "place-fldcr",
    "place-shmnl"
  ]

  def excluded_origin_stops(0, "Red", _all_stops) do
    ["place-brntn", "place-asmnl"]
  end
  def excluded_origin_stops(0, "Green", _) do
    ["place-lake", "place-clmnl", "place-river", "place-hsmnl"]
  end
  def excluded_origin_stops(_direction_id, _route_id, []) do
    []
  end
  def excluded_origin_stops(_direction_id, _route_id, all_stops) do
    [List.last(all_stops).id]
  end

  def excluded_destination_stops("Red", origin_id) when origin_id in @braintree_stops do
    @ashmont_stops
  end
  def excluded_destination_stops("Red", origin_id) when origin_id in @ashmont_stops do
    @braintree_stops
  end
  def excluded_destination_stops("Green", origin_id) do
    stops_on_routes = GreenLine.stops_on_routes(0)

    # Determine which lines the origin is *not* on, and union together all their stops.
    ~w(Green-B Green-C Green-D Green-E)
    |> Enum.reject(& GreenLine.stop_on_route?(origin_id, &1, stops_on_routes))
    |> Enum.reduce(MapSet.new, & MapSet.union(GreenLine.route_stops(&1, stops_on_routes), &2))
  end
  def excluded_destination_stops(_route_id, _origin_id), do: []
end
