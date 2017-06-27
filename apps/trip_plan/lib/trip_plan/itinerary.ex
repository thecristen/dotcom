defmodule TripPlan.Itinerary do
  @moduledoc """
  A trip at a particular time.

  An Itinerary is a single trip, with the legs being the different types of
  travel. Itineraries are separate even if they use the same modes but happen
  at different times of day.
  """
  @enforce_keys [:start, :stop]
  defstruct [
    :start,
    :stop,
    legs: []
  ]
  @type t :: %__MODULE__{
    start: DateTime.t,
    stop: DateTime.t,
    legs: [TripPlan.Leg.t]
  }

  @doc "Return a list of all the route IDs used for this Itinerary"
  @spec route_ids(t) :: [Routes.Route.id_t]
  def route_ids(%__MODULE__{legs: legs}) do
    flat_map_over_legs(legs, &TripPlan.Leg.route_id/1)
  end

  @doc "Return a list of all the trip IDs used for this Itinerary"
  @spec trip_ids(t) :: [Schedules.Trip.id_t]
  def trip_ids(%__MODULE__{legs: legs}) do
    flat_map_over_legs(legs, &TripPlan.Leg.trip_id/1)
  end

  @doc "Return a list of all the stop IDs used for this Itinerary"
  @spec stop_ids(t) :: [Schedules.Trip.id_t]
  def stop_ids(%__MODULE__{legs: legs}) do
    legs
    |> Enum.flat_map(&TripPlan.Leg.stop_ids/1)
    |> Enum.uniq
  end

  defp flat_map_over_legs(legs, mapper) do
    for leg <- legs, {:ok, value} <- leg |> mapper.() |> List.wrap do
      value
    end
  end
end
