defmodule TripPlan.Leg do
  @moduledoc """
  A single-mode part of an Itinerary

  An Itinerary can take multiple modes of transportation (car, walk, bus,
  train, &c). Leg represents a single mode of travel during journey.
  """
  alias TripPlan.{PersonalDetail, TransitDetail}
  alias Stops.Position

  defstruct [
    start: DateTime.from_unix!(-1),
    stop: DateTime.from_unix!(0),
    mode: nil,
    from: nil,
    to: nil,
    polyline: ""
  ]

  @type mode :: PersonalDetail.t | TransitDetail.t
  @type t :: %__MODULE__{
    start: DateTime.t,
    stop: DateTime.t,
    mode: mode,
    from: Position.t,
    to: Position.t,
    polyline: String.t
  }

  @doc "Returns the route ID for the leg, if present"
  @spec route_id(t) :: {:ok, Routes.Route.id_t} | :error
  def route_id(%__MODULE__{mode: %TransitDetail{route_id: route_id}}), do: {:ok, route_id}
  def route_id(%__MODULE__{}), do: :error

  @doc "Returns the trip ID for the leg, if present"
  @spec trip_id(t) :: {:ok, Schedules.Trip.id_t} | :error
  def trip_id(%__MODULE__{mode: %TransitDetail{trip_id: trip_id}}), do: {:ok, trip_id}
  def trip_id(%__MODULE__{}), do: :error

  @doc "Returns the stop IDs for the leg"
  @spec stop_ids(t) :: [Stops.Stop.id_t]
  def stop_ids(%__MODULE__{from: from, to: to}) do
    for %{stop_id: stop_id} <- [from, to] do
      stop_id
    end
  end
end
