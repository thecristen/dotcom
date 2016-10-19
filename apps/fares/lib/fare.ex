defmodule Fares.Fare do
  @typedoc """
    struct(
      mode: :commuter | :bus | :subway | :ferry,
      name: {:zone, "5"} | :subway_student | etc
      pass_type: :ticket | :charlie_card | :mticket | :link_pass
      reduced: :student | :senior_disabled | nil
      duration: :single_trip | :day | :week | :month
      cents: cost_in_cents
    )
  """
  @type fare_name :: {atom, String.t()} | atom
  @type pass_type :: :ticket | :charlie_card | :mticket | :link_pass
  @type reduced :: nil | :student | :senior_disabled
  @type duration :: :single_trip | :round_trip | :day | :week | :month
  @type t :: %__MODULE__{
    mode: Routes.Route.route_type,
    name: fare_name,
    pass_type: pass_type,
    reduced: reduced,
    duration: duration,
    cents: non_neg_integer
  }

  defstruct [
    mode: nil,
    name: nil,
    pass_type: nil,
    reduced: nil,
    duration: nil,
    cents: 0,
  ]
end
