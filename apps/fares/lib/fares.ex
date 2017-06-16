defmodule Fares do
  @type ferry_name :: :ferry_cross_harbor | :ferry_inner_harbor | :commuter_ferry_logan | :commuter_ferry

  def fare_for_stops(:commuter_rail, origin, destination) do
    calculate_commuter_rail(Zones.Repo.get(origin), Zones.Repo.get(destination))
  end
  def fare_for_stops(:ferry, origin, destination) do
    calculate_ferry(origin, destination)
  end

  def calculate_commuter_rail(start_zone, "1A") do
    {:zone, start_zone}
  end
  def calculate_commuter_rail("1A", end_zone) do
    {:zone, end_zone}
  end
  def calculate_commuter_rail(start_zone, end_zone) do
    # we need to include all zones travelled in, ie zone 3 -> 5 is 3 zones
    total_zones = abs(String.to_integer(start_zone) - String.to_integer(end_zone)) + 1

    {:interzone, "#{total_zones}"}
  end

  @spec calculate_ferry(String.t, String.t) :: ferry_name
  defp calculate_ferry(origin, destination)
  when "Boat-Charlestown" in [origin, destination] and "Boat-Logan" in [origin, destination] do
    :ferry_cross_harbor
  end
  defp calculate_ferry(origin, destination) when "Boat-Charlestown" in [origin, destination] do
    :ferry_inner_harbor
  end
  defp calculate_ferry(origin, destination) when "Boat-Logan" in [origin, destination] do
    :commuter_ferry_logan
  end
  defp calculate_ferry(_origin, _destination) do
    :commuter_ferry
  end
end
