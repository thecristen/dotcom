defmodule Fares do

  def calculate(start_zone, :zone_1a) do
    Fares.Repo.all(name: start_zone)
  end
  def calculate(:zone_1a, end_zone) do
    Fares.Repo.all(name: end_zone)
  end
  def calculate(start_zone, end_zone) do
    zones = %{
      zone_1: 1,
      zone_2: 2,
      zone_3: 3,
      zone_4: 4,
      zone_5: 5,
      zone_6: 6,
      zone_6: 7,
      zone_6: 8,
      zone_6: 9,
      zone_6: 10
    }

    total_zones = abs(zones[start_zone] - zones[end_zone]) + 1 # need to include the starting zone

    Fares.Repo.all(name: quote do: unquote(:"interzone_#{total_zones}"))
  end

end
