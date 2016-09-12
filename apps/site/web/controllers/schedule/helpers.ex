defmodule Site.ScheduleController.Helpers do
  import Plug.Conn
  import Site.Router.Helpers
  import Util
  use Timex

  @doc "Assign @datetime, a relevant time to use for filtering alerts"
  def assign_datetime(%{assigns: %{trip_schedule: [schedule|_]}} = conn) do
    conn
    |> assign(:datetime, schedule.time)
  end
  def assign_datetime(%{assigns: %{date: date}} = conn) do
    datetime = if Timex.equal?(today, date) do
      now
    else
      date
      |> Timex.to_datetime("America/New_York")
      |> Timex.set(hour: 12)
    end

    conn
    |> assign(:datetime, datetime)
  end

  @doc """
  If a trip is selected (via the `trip` parameter), fetches that trip and assigns
  it as @trip_schedule.  Otherwise, assigns nil to @trip.
  """
  def assign_selected_trip(%{params: %{"trip" => trip_id}} = conn) do
    conn
    |> assign(:trip, trip_id)
    |> async_assign(:trip_schedule, fn ->
      do_selected_trip(trip_id)
    end)
  end
  def assign_selected_trip(conn) do
    conn
    |> assign(:trip, nil)
    |> assign(:trip_schedule, nil)
  end

  defp do_selected_trip("") do
    nil
  end
  defp do_selected_trip(trip_id) do
    Schedules.Repo.trip(trip_id)
  end

  @doc """
  Given a filtered list, the full list, and a Conn, returns a tuple of {list, conn}.

  If the filtered list is empty, returns the full list and sets @show_all
  in the Conn.  Otherwise, returns the filtered list and the Conn unmodified.
  """
  def possibly_open_schedules([], all_schedules, conn) do
    {all_schedules, assign(conn, :show_all, true)}
  end
  def possibly_open_schedules(schedules, _, conn) do
    {schedules, conn}
  end

  @doc "Given a list of values, return the one which appears the most"
  def most_frequent_value(values) do
    values
    |> Enum.group_by(&(&1))
    |> Enum.max_by(fn {_, items} -> length(items) end)
    |> (fn {value, _} -> value end).()
  end

  @doc "Returns true if the Schedule is in the future"
  def is_after_now?(%Schedules.Schedule{time: time}) do
    time
    |> Timex.after?(now)
  end

  @doc "Given a list of schedules, return where those schedules start (best-guess)"
  def from(all_schedules, %{assigns: %{all_stops: all_stops}}) do
    stop_id = all_schedules
    |> Enum.map(fn schedule -> schedule.stop.id end)
    |> most_frequent_value

    # Use the parent station from all_stops
    all_stops
    |> Enum.find(fn stop -> stop.id == stop_id end)
  end

  @doc "Given a list of schedules, return where those schedules stop"
  def to(all_schedules) do
    all_schedules
    |> Enum.map(fn schedule -> schedule.trip.headsign end)
    |> Enum.uniq
  end

  @doc "Fetches the route from `conn.assigns` and assigns breadcrumbs."
  def assign_route_breadcrumbs(%{assigns: %{route: %{name: name, type: type}}} = conn) do
    route_type_display =
      case type do
        2 -> {mode_path(conn, :commuter_rail), "Commuter Rail"}
        3 -> {mode_path(conn, :bus), "Bus"}
        4 -> {mode_path(conn, :boat), "Boat"}
        _ -> {mode_path(conn, :subway), "Subway"}
      end
    conn
    |> assign(:breadcrumbs, [{mode_path(conn, :index), "Schedules & Maps"}, route_type_display, name])
  end
end
