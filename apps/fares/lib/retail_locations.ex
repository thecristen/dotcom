defmodule Fares.RetailLocations do
  alias __MODULE__.Location
  alias __MODULE__.Data

  @locations Data.build_r_tree()

  @doc """
    Takes a latitude and longitude and returns the four closest retail locations for purchasing fares.
  """
  @spec get_nearby(Stops.Position.t) :: [{Location.t, float}]
  def get_nearby(lat_long) do
    @locations
    |> Data.k_nearest_neighbors(lat_long, 4)
    |> Enum.map(fn l -> {l, Stops.Distance.haversine(l, lat_long)} end)
  end
end
