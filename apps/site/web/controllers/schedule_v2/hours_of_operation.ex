defmodule Site.ScheduleV2Controller.HoursOfOperation do

  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(%Plug.Conn{assigns: %{route: route}} = conn, opts) when not is_nil(route) do
    dates = get_dates(conn.assigns.date)
    schedules_fn = schedules_fn(opts)
    assign(conn, :hours_of_operation, %{
          :week => get_hours(conn, dates[:week], schedules_fn),
          :saturday => get_hours(conn, dates[:saturday], schedules_fn),
          :sunday => get_hours(conn, dates[:sunday], schedules_fn)}
    )
  end
  def call(conn, _opts) do
    conn
  end

  defp get_hours(%Plug.Conn{assigns: %{route: %Routes.Route{id: "Green"}}}, date, schedules_fn) do
    do_get_hours(Enum.join(GreenLine.branch_ids(), ","), date, schedules_fn)
  end
  defp get_hours(%Plug.Conn{assigns: %{route: route}}, date, schedules_fn) do
    do_get_hours(route.id, date, schedules_fn)
  end

  defp do_get_hours(route_id, date, schedules_fn) do
    {inbound, outbound} = [date: date, stop_sequence: "first,last"]
    |> Keyword.merge(route: route_id)
    |> schedules_fn.()
    |> Enum.split_with(& &1.trip.direction_id == 1)

    %{
      1 => Schedules.Departures.first_and_last_departures(inbound),
      0 => Schedules.Departures.first_and_last_departures(outbound)
    }
  end

  defp get_dates(date) do
    %{
      :week => Timex.end_of_week(date, 2),
      :saturday => Timex.end_of_week(date, 7),
      :sunday => Timex.end_of_week(date, 1)
    }
  end

  defp schedules_fn(opts) do
    Keyword.get(opts, :schedules_fn, &Schedules.Repo.all/1)
  end
end
