defmodule Site.FareController.Ferry do
  use Site.FareController.OriginDestinationFareBehavior

  alias Schedules.Stop

  def route_type, do: 4

  def mode, do: :ferry

  def fares(%{assigns: %{origin: %Stop{id: origin}, destination: %Stop{id: destination}}}) do
    Fares.Repo.all(name: fare_name(origin, destination))
  end
  def fares(_conn) do
    []
  end

  @type ferry_name :: :ferry_cross_harbor | :ferry_inner_harbor | :commuter_ferry_logan | :commuter_ferry

  @spec fare_name(String.t, String.t) :: ferry_name
  def fare_name(origin, destination)
  when "Boat-Charlestown" in [origin, destination] and "Boat-Logan" in [origin, destination] do
    :ferry_cross_harbor
  end
  def fare_name(origin, destination) when "Boat-Charlestown" in [origin, destination] do
    :ferry_inner_harbor
  end
  def fare_name(origin, destination) when "Boat-Logan" in [origin, destination] do
    :commuter_ferry_logan
  end
  def fare_name(_origin, _destination) do
    :commuter_ferry
  end

  def key_stops, do: []
end
