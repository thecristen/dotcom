defmodule Fares.Fare do
  @typedoc """

  Represents a method of paying for transit on the MBTA.

  """
  @type fare_name :: {atom, String.t()} | atom
  @type pass_type :: :ticket
  | :cash_or_ticket
  | :charlie_card
  | :mticket
  | :card_or_ticket
  | :student_card
  | :senior_card
  @type reduced :: nil | :student | :senior_disabled
  @type duration :: :single_trip | :round_trip | :day | :week | :month
  @type t :: %__MODULE__{
    mode: Routes.Route.route_type,
    name: fare_name,
    pass_type: pass_type,
    reduced: reduced,
    duration: duration,
    cents: non_neg_integer,
    additional_valid_modes: [Routes.Route.route_type]
  }

  defstruct [
    mode: nil,
    name: nil,
    pass_type: nil,
    reduced: nil,
    duration: nil,
    cents: 0,
    additional_valid_modes: []
  ]
end
