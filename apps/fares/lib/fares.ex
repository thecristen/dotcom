defmodule Fares do
  @type ferry_name :: :ferry_cross_harbor | :ferry_inner_harbor | :commuter_ferry_logan | :commuter_ferry

  @spec fare_for_stops(:commuter_rail | :ferry, Stops.Stop.id_t, Stops.Stop.id_t) :: {:ok, Fares.Fare.fare_name} |
  :error
  def fare_for_stops(route_type_atom, origin_id, destination_id)
  def fare_for_stops(:commuter_rail, origin, destination)
  when origin == "Foxboro" or destination == "Foxboro" do
    {:ok, :foxboro}
  end
  def fare_for_stops(:commuter_rail, origin, destination) do
    with origin_zone when not is_nil(origin_zone) <- Zones.Repo.get(origin),
         dest_zone when not is_nil(dest_zone) <- Zones.Repo.get(destination) do
      {:ok, calculate_commuter_rail(Zones.Repo.get(origin), Zones.Repo.get(destination))}
    else
      _ -> :error
    end
  end
  def fare_for_stops(:ferry, origin, destination) do
    {:ok, calculate_ferry(origin, destination)}
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
  defp calculate_ferry(origin, destination)
  when "Boat-Long" in [origin, destination] and "Boat-Logan" in [origin, destination] do
    :ferry_cross_harbor
  end
  defp calculate_ferry(origin, destination)
  when "Boat-Charlestown" in [origin, destination] and "Boat-Long-South" in [origin, destination] do
    :ferry_inner_harbor
  end
  defp calculate_ferry(origin, destination) when "Boat-Logan" in [origin, destination] do
    :commuter_ferry_logan
  end
  defp calculate_ferry(_origin, _destination) do
    :commuter_ferry
  end
end
