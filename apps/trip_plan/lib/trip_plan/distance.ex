defmodule TripPlan.Distance do
  @moduledoc """
  Helper functions for working with distances.
  """

  @feet_in_meter 3.28084
  @meters_in_mile 1609.34

  @doc """
  Converts a distance in meters to a friendly imperial (feet, miles) iodata.

  # Examples

  iex> import TripPlan.Distance, only: [meters_to_imperial: 1]
  iex> meters_to_imperial(44.805)
  ["147", " feet"]
  iex> meters_to_imperial(692)
  ["0.43", " miles"]
  iex> meters_to_imperial(8272)
  ["5.1", " miles"]
  """
  @spec meters_to_imperial(number) :: iodata
  def meters_to_imperial(meters) when meters < @meters_in_mile / 10 do
    feet = round(meters * @feet_in_meter)
    [Integer.to_string(feet), " feet"]
  end
  def meters_to_imperial(meters) when meters < @meters_in_mile do
    miles = Float.round(meters / @meters_in_mile, 2)
    [Float.to_string(miles), " miles"]
  end
  def meters_to_imperial(meters) do
    miles = Float.round(meters / @meters_in_mile, 1)
    [Float.to_string(miles), " miles"]
  end
end
