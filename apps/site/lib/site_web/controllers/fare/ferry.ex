defmodule SiteWeb.FareController.Ferry do
  use SiteWeb.FareController.OriginDestinationFareBehavior

  @impl true
  def route_type, do: 4

  @impl true
  def mode, do: :ferry

  @impl true
  def fares(%{assigns: %{origin: origin, destination: destination}})
  when not is_nil(origin) and not is_nil(destination) do
    case Fares.fare_for_stops(:ferry, origin.id, destination.id) do
      {:ok, name} -> Fares.Repo.all(name: name)
      :error -> []
    end
  end
  def fares(_conn) do
    []
  end
end
