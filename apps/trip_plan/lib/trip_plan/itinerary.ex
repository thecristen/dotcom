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

  @doc "Returns a list of all the named positions for this Itinerary"
  @spec positions(t) :: [TripPlan.NamedPosition.t]
  def positions(%__MODULE__{legs: legs}) do
    Enum.flat_map(legs, &[&1.from, &1.to])
  end

  @doc "Return a list of all the stop IDs used for this Itinerary"
  @spec stop_ids(t) :: [Schedules.Trip.id_t]
  def stop_ids(%__MODULE__{} = itinerary) do
    itinerary
    |> positions
    |> Enum.map(& &1.stop_id)
    |> Enum.uniq
  end

  defp flat_map_over_legs(legs, mapper) do
    for leg <- legs, {:ok, value} <- leg |> mapper.() |> List.wrap do
      value
    end
  end
end

defimpl Enumerable, for: TripPlan.Itinerary do
  def count(_itinerary) do
    {:error, __MODULE__}
  end

  def member?(_itinerary, %TripPlan.Leg{}) do
    {:error, __MODULE__}
  end
  def member?(_itinerary, _other) do
    {:ok, false}
  end

  def reduce(%{legs: legs}, acc, fun) do
    Enumerable.reduce(legs, acc, fun)
  end
end
