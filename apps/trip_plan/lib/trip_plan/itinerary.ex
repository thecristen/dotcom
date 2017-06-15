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
    Enum.flat_map(legs, fn leg ->
      case TripPlan.Leg.route_id(leg) do
        {:ok, route_id} -> [route_id]
        :error -> []
      end
    end)
  end
end
