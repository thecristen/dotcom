defmodule Fares.RetailLocations do
  alias Stops.Stop
  alias __MODULE__.Location

  @locations __MODULE__.Data.get

  @doc """
    Takes a latitude and longitude and returns the four closest retail locations for purchasing fares.
  """
  @spec get_nearby(Stop.t) :: [{Location.t, float}]
  def get_nearby(stop) do
    @locations
    |> Enum.map(&{&1, Stops.Distance.haversine(&1, stop)})
    |> Enum.sort_by(fn {_, distance} -> distance end)
    |> Enum.take(4)
  end
end
