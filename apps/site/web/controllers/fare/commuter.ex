defmodule Site.FareController.Commuter do
  use Site.FareController.OriginDestinationFareBehavior

  alias Schedules.Stop

  def route_type, do: 2

  def mode, do: :commuter_rail

  def fares(%{assigns: %{origin: origin, destination: destination}}) when not is_nil(origin) and not is_nil(destination) do
    fare_name = Fares.calculate(Zones.Repo.get(origin.id), Zones.Repo.get(destination.id))

    Fares.Repo.all(name: fare_name)
  end
  def fares(_conn) do
    []
  end

  def key_stops do
    [
      %Stop{id: "place-sstat", name: "South Station"},
      %Stop{id: "place-north", name: "North Station"},
      %Stop{id: "place-bbsta", name: "Back Bay"}
    ]
  end
end
