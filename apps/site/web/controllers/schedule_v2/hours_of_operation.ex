defmodule Site.ScheduleV2Controller.HoursOfOperation do

  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(%Plug.Conn{assigns: %{route: route}} = conn, opts) when not is_nil(route) do
    conn.assigns.date
    |> get_dates()
    |> Enum.map(fn date -> do_call(date, conn, Keyword.get(opts, :schedules_fn, &Schedules.Repo.by_route_ids/2)) end)
    |> Enum.flat_map(fn {key, task} ->
      case Task.yield(task) do
        nil ->
          []
        {:ok, schedules} ->
          [{key, schedules}]
      end
    end)
    |> Enum.into(%{})
    |> assign_hours(conn)
  end
  def call(conn, _opts) do
    conn
  end

  defp do_call({key, date}, conn, schedules_fn) do
    {key, Task.async(fn -> get_hours(conn, date, schedules_fn) end)}
  end

  defp assign_hours(hours, conn), do: assign(conn, :hours_of_operation, hours)

  defp get_hours(%Plug.Conn{assigns: %{route: %Routes.Route{id: "Green"}}}, date, schedules_fn) do
    do_get_hours(GreenLine.branch_ids(), date, schedules_fn)
  end
  defp get_hours(%Plug.Conn{assigns: %{route: route}}, date, schedules_fn) do
    do_get_hours([route.id], date, schedules_fn)
  end

  defp do_get_hours(route_ids, date, schedules_fn) do
    {inbound, outbound} = route_ids
    |> schedules_fn.(date: date, stop_sequences: ~w(first last)s)
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
end
