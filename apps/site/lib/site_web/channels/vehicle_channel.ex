defmodule SiteWeb.VehicleChannel do
  use SiteWeb, :channel
  alias Site.MapHelpers.Markers
  alias Vehicles.Vehicle

  intercept ["reset", "add", "update", "remove"]

  @impl Phoenix.Channel
  def join("vehicles:" <> _params, %{}, socket) do
    {:ok, socket}
  end

  @spec handle_out(String.t, %{required(:data) => [Vehicle.t]}, Phoenix.Socket.t)
  :: {:noreply, Phoenix.Socket.t}
  def handle_out(event, %{data: vehicles}, socket) when event in ["reset", "add", "update"] do
    push socket, "data", %{event: event, data: Enum.map(vehicles, &build_marker/1)}
    {:noreply, socket}
  end
  def handle_out("remove", %{data: ids}, socket) do
    push socket, "data", %{
      event: "remove",
      data: Enum.map(ids, &Markers.vehicle_marker_id/1)
    }
    {:noreply, socket}
  end

  @type data_map :: %{
    required(:data) => Vehicle.t,
    required(:marker) => GoogleMaps.MapData.Marker.t
  }
  @spec build_marker(Vehicles.Vehicle.t) :: data_map
  def build_marker(%Vehicles.Vehicle{} = vehicle) do
    route = Routes.Repo.get(vehicle.route_id)
    stop_name = get_stop_name(vehicle.stop_id)
    trip = Schedules.Repo.trip(vehicle.trip_id)
    marker = Markers.vehicle(
      %VehicleTooltip{
        prediction: nil,
        vehicle: vehicle,
        route: route,
        stop_name: stop_name,
        trip: trip
      }
    )

    %{
      data: vehicle,
      marker: marker
    }
  end

  @spec get_stop_name(String.t | nil) :: String.t
  defp get_stop_name(nil) do
    ""
  end
  defp get_stop_name(stop_id) do
    case Stops.Repo.get(stop_id) do
      nil -> ""
      %Stops.Stop{name: name} -> name
    end
  end
end
