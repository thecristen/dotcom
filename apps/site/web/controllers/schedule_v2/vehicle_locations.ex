defmodule Site.ScheduleV2Controller.VehicleLocations do
  @moduledoc """
  Assigns vehicle locations corresponding to the already-assigned schedules, if they exist.
  """
  import Plug.Conn, only: [assign: 3]

  alias Stops.Stop

  @default_opts [
    location_fn: &Vehicles.Repo.route/2,
    schedule_for_trip_fn: &Schedules.Repo.schedule_for_trip/1
  ]

  def init(opts) do
    Keyword.merge(@default_opts, opts)
  end

  def call(conn, opts) do
    locations = if should_fetch_vehicles?(conn) do
      find_locations(conn, opts)
    else
      %{}
    end
    assign(conn, :vehicle_locations, locations)
  end

  # don't fetch vehicles for non-commuter rail without an origin.  otherwise
  # make sure the date is today.
  defp should_fetch_vehicles?(%{assigns: %{route: %{type: not_commuter_rail}, origin: nil}})
  when not_commuter_rail != 2 do
    false
  end
  defp should_fetch_vehicles?(conn) do
    conn.assigns.date == Util.service_date(conn.assigns.date_time)
  end

  defp find_locations(%Plug.Conn{assigns: %{route: route, direction_id: direction_id}}, opts) do
    route.id
    |> opts[:location_fn].(direction_id: direction_id)
    |> Map.new(&{location_key(&1, opts[:schedule_for_trip_fn]), &1})
  end

  defp location_key(%Vehicles.Vehicle{status: :in_transit} = vehicle, schedule_for_trip_fn) do
    previous_station = vehicle.trip_id
    |> schedule_for_trip_fn.()
    |> find_previous_station(vehicle.stop_id)

    {vehicle.trip_id, previous_station.id}
  end
  defp location_key(vehicle, _) do
    {vehicle.trip_id, vehicle.stop_id}
  end

  defp find_previous_station([_], _stop_id), do: nil
  defp find_previous_station([previous_stop_schedule, %Schedules.Schedule{stop: %Stop{id: id}} | _rest], stop_id) when id == stop_id do
    previous_stop_schedule.stop
  end
  defp find_previous_station([_previous, stop_schedule | rest], stop_id) do
    find_previous_station([stop_schedule | rest], stop_id)
  end
end
