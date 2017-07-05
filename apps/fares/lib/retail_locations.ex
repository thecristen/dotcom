defmodule Fares.RetailLocations do
  alias __MODULE__.Location

  @locations __MODULE__.Data.get

  @doc """
    Takes a latitude and longitude and returns the four closest retail locations for purchasing fares.
  """
  @spec get_nearby(Stops.Position.t) :: [{Location.t, float}]
  def get_nearby(lat_long) do
    @locations
    |> Enum.map(&{&1, Stops.Distance.haversine(&1, lat_long)})
    |> Enum.sort_by(fn {_, distance} -> distance end)
    |> Enum.take(4)
  end
end
