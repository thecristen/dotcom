defmodule Fare do
  @typedoc """
    name: :zone_1 | :interzone_4 | etc
    pass_type: :ticket | :charlie_card | :mticket
    reduced: :student | :senior_disabled
    duration: :single_trip | :month
    cents: <cost in cents>
  """
  defstruct [
    name: nil,
    pass_type: nil,
    reduced: nil,
    duration: nil,
    cents: 0,
  ]
end
