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
end
