defmodule Fares do

  def calculate(start_zone, "1A") do
    Fares.Repo.all(name: quote do: unquote(:"zone_#{start_zone}"))
  end
  def calculate("1A", end_zone) do
    Fares.Repo.all(name: quote do: unquote(:"zone_#{end_zone}"))
  end
  def calculate(start_zone, end_zone) do
    # we need to include all zones travelled in, ie zone 3 -> 5 is 3 zones
    total_zones = abs(String.to_integer(start_zone) - String.to_integer(end_zone)) + 1

    Fares.Repo.all(name: quote do: unquote(:"interzone_#{total_zones}"))
  end

end
