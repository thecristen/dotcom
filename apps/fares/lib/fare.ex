defmodule Fares.Fare do
  @typedoc """
    struct(
      mode: :commuter | :bus | :subway | :boat,
      name: {:zone, "5"} | :subway_student | etc
      pass_type: :ticket | :charlie_card | :mticket | :link_pass
      reduced: :student | :senior_disabled
      duration: :single_trip | :week | :month
      cents: cost_in_cents
    )
  """
  @type t :: %__MODULE__{
    mode: :commuter | :bus | :subway | :boat,
    name: {atom, String.t()} | atom,
    pass_type: :ticket | :charlie_card | :mticket | :link_pass,
    reduced: :student | :senior_disabled,
    duration: :single_trip | :week | :month,
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
