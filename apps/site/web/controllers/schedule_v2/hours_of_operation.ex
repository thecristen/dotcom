defmodule Site.ScheduleV2Controller.HoursOfOperation do
  @behaviour Plug
  import Plug.Conn, only: [assign: 3]
  alias Schedules.HoursOfOperation

  @impl true
  def init([]), do: []

  @impl true
  def call(%Plug.Conn{assigns: %{route: route}} = conn, _opts) when not is_nil(route) do
    route.id
    |> full_route_id
    |> Schedules.Repo.hours_of_operation
    |> restructure_result
    |> assign_hours(conn)
  end
  def call(conn, _opts) do
    conn
  end

  defp full_route_id("Green") do
    GreenLine.branch_ids()
  end
  defp full_route_id(route_id) do
    route_id
  end

  def restructure_result(hours) when hours == %HoursOfOperation{} do
    %{}
  end
  def restructure_result(hours) do
    %{
      week: restructure_departures(hours.week),
      saturday: restructure_departures(hours.saturday),
      sunday: restructure_departures(hours.sunday)
    }
  end

  defp restructure_departures({:no_service, :no_service}) do
    nil
  end
  defp restructure_departures({departures_0, departures_1}) do
    map = if departures_0 == :no_service do
      %{}
    else
      %{0 => departures_0}
    end
    if departures_1 == :no_service do
      map
    else
      Map.put(map, 1, departures_1)
    end
  end

  defp assign_hours(hours, conn) when hours == %{}, do: conn
  defp assign_hours(hours, conn), do: assign(conn, :hours_of_operation, hours)
end
