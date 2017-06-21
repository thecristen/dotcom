defmodule Site.BaseFare do
  @moduledoc """
  Calculates the "base fare" for a particular trip.
  The base fare is a regular priced, one-way fare for the given mode.
  If there are multiple fare media, the lowest priced is chosen.
  Commuter rail and ferry fares distinguish between the possible sets of stops.
  Bus fares for express buses do not distinguish between the local and express portions;
  the express fare is always returned.
  """

  alias Routes.Route
  alias Fares.Fare

  @default_filters [duration: :single_trip, reduced: nil]

  @spec base_fare(Route.t, Stops.Stop.id_t, Stops.Stop.id_t, ((Keyword.t) -> [Fare.t])) :: String.t
  def base_fare(route, origin_id, destination_id, fare_fn \\ &Fares.Repo.all/1)
  def base_fare(nil, _, _, _), do: nil
  def base_fare(%Route{type: route_type} = route, origin_id, destination_id, fare_fn) do
    route_type
    |> Route.type_atom
    |> name_or_mode_filter(route, origin_id, destination_id)
    |> Keyword.merge(@default_filters)
    |> fare_fn.()
    |> Enum.min_by(&(&1.cents))
  end

  defp name_or_mode_filter(:subway, _route, _origin_id, _destination_id) do
    [mode: :subway]
  end
  defp name_or_mode_filter(:bus, route, _origin_id, _destination_id) do
    name = cond do
      Route.inner_express?(route) -> :inner_express_bus
      Route.outer_express?(route) -> :outer_express_bus
      true -> :local_bus
    end

    [name: name]
  end
  defp name_or_mode_filter(:commuter_rail, _route, origin_id, destination_id) do
    name = Fares.fare_for_stops(:commuter_rail, origin_id, destination_id)

    [name: name]
  end
  defp name_or_mode_filter(:ferry, _route, origin_id, destination_id) do
    name = Fares.fare_for_stops(:ferry, origin_id, destination_id)

    [name: name]
  end
end
