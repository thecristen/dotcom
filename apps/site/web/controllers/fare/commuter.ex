defmodule Site.FareController.Commuter do
  use Site.FareController.OriginDestinationFareBehavior

  @impl true
  def route_type, do: 2

  @impl true
  def mode, do: :commuter_rail

  @impl true
  def fares(%{assigns: %{origin: origin, destination: destination}}) when not is_nil(origin) and not is_nil(destination) do
    fare_name = Fares.fare_for_stops(:commuter_rail, origin.id, destination.id)

    Fares.Repo.all(name: fare_name)
  end
  def fares(_conn) do
    []
  end

  @impl true
  def key_stops do
    for stop_id <- ~w(place-sstat place-north place-bbsta)s do
      Stops.Repo.get!(stop_id)
    end
  end
end
