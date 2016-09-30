defmodule Fare do
  defstruct [
    name: nil, # :zone_1 | :interzone_4 etc
    pass_type: nil, # :ticket | :charlie_card | :mticket
    reduced: nil, # :student | :senior_disabled
    duration: nil, # :single_trip | :month
    cents: 0, # cost in cents
  ]
end
