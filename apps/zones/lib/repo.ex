defmodule Zones.Repo do

  def zone_info do
    File.stream!("priv/crzones.csv") |> CSV.decode |> Enum.map(fn row -> Enum.map(row, &String.upcase/1) end)
  end

  def get(stop) do
    zone_info
    |> Enum.find_value(fn [station|zone] -> if station == String.upcase(stop) do List.first(zone) end end)
  end

  def all do
    zone_info
    |> Enum.reduce(Map.new, fn [station| zone], station_zone_map -> Map.put(station_zone_map, station, List.last(zone)) end)
  end
end
