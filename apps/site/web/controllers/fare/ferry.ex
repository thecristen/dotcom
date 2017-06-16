defmodule Site.FareController.Ferry do
  use Site.FareController.OriginDestinationFareBehavior

  def route_type, do: 4

  def mode, do: :ferry

  def fares(%{assigns: %{origin: origin, destination: destination}})
  when not is_nil(origin) and not is_nil(destination) do
    Fares.Repo.all(name: Fares.fare_for_stops(:ferry, origin.id, destination.id))
  end
  def fares(_conn) do
    []
  end

  def key_stops, do: []
end
