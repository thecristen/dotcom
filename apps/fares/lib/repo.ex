defmodule Fares.Repo.ZoneFares do
  def fare_info do
    filename = "priv/zone_fares.csv"

    zone_fares = filename
    |> File.stream!
    |> CSV.decode
    |> Enum.reduce(Map.new, fn [zone| [one_way, one_way_reduced, monthly]], station_zone_map ->
      Map.put(station_zone_map, zone, %{one_way: one_way, one_way_reduced: one_way_reduced, monthly: monthly})
    end)
  end
end

defmodule Fares.Repo do
  import Fares.Repo.ZoneFares
  @zone_fares fare_info

  def one_way(zone) do
    @zone_fares[zone][:one_way]
  end

  def one_way_reduced(zone) do
    @zone_fares[zone][:one_way_reduced]
  end

  def monthly(zone) do
    @zone_fares[zone][:monthly]
  end
end
