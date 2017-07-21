defmodule TripPlan.Api do
  @moduledoc """
  Behaviour for planning modules.

  They must implement the `plan/3` function, which takes an origin, destination and options,
  and returns either a list of %Itinerary{} or an error.

  """
  alias TripPlan.Itinerary
  alias Stops.Position

  @type plan_opt :: {:arrive_by, DateTime.t} |
  {:depart_at, DateTime.t} |
  {:wheelchair_accessible?, boolean} |
  {:max_walk_distance, float}
  @type plan_opts :: [plan_opt]
  @type t :: {:ok, [Itinerary.t]} | {:error, any}

  @doc """
  Plans a trip between two locations.
  """
  @callback plan(from :: Position.t, to :: Position.t, opts :: plan_opts) :: t
end
