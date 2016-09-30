defmodule Fare do
  @typedoc """
    struct(
      name: :zone_1 | :interzone_4 | etc
      pass_type: :ticket | :charlie_card | :mticket
      reduced: :student | :senior_disabled
      duration: :single_trip | :month
      cents: cost_in_cents
    )
  """
  @type fare :: %Fare{name: :atom, pass_type: :atom, reduced: :atom, duration: :atom, cents: integer}
  defstruct [
    name: nil,
    pass_type: nil,
    reduced: nil,
    duration: nil,
    cents: 0,
  ]
end
