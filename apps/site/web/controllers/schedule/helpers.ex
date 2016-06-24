defmodule Site.ScheduleController.Helpers do
  import Plug.Conn
  use Timex

  @doc "Find all the assigns which are Tasks, and await_assign them"
  def await_assign_all(conn) do
    conn.assigns
    |> Enum.filter_map(
    fn
      {_, %Task{}} -> true
      _ -> false
    end,
    fn {key, _} -> key end)
    |> Enum.reduce(conn, fn key, conn -> await_assign(conn, key) end)
  end

  @doc "Fetch the alerts and assign them"
  def assign_alerts(conn) do
    conn
    |> async_assign(:alerts, &Alerts.Repo.all/0)
  end

  @doc "Fetch a route and assign it as @route"
  def assign_route(conn, route_id) do
    conn
    |> assign(:route, Routes.Repo.get(route_id))
  end

  @doc "Fetch all the stops on a route and assign them as @all_stops"
  def assign_all_stops(conn, route_id) do
    conn
    |> assign(:all_stops,
    Schedules.Repo.stops(
      route_id,
      date: conn.assigns[:date],
      direction_id: conn.assigns[:direction_id]))
  end

  @doc """
  Once @route is set, fetches all the routes with that same type and assigns them
  as @all_routes
  """
  def assign_all_routes(%{assigns: %{route: %{type: type}}} = conn) do
    conn
    |> assign(:all_routes, Routes.Repo.by_type(type))
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
    { all_schedules, assign(conn, :show_all, true) }
  end
  def possibly_open_schedules(schedules, _, conn) do
    { schedules, conn }
  end

  @doc "Given a list of values, return the one which appears the most"
  def most_frequent_value(values) do
    values
    |> Enum.group_by(&(&1))
    |> Enum.into([])
    |> Enum.max_by(fn {_, items} -> length(items) end)
    |> (fn {value, _} -> value end).()
  end

  @doc "Returns true if the Schedule is in the future"
  def is_after_now?(%Schedules.Schedule{time: time}) do
    time
    |> Timex.after?(DateTime.now)
  end

  @doc """
  Fetches the route and the full list of alerts from `conn.assigns` and assigns a filtered list
  of alerts for that route.
  """
  def route_alerts(%{assigns: %{alerts: alerts, route: route}} = conn) do
    route_alerts = alerts
    |> Alerts.Match.match(%Alerts.InformedEntity{route: route.id})
    |> Enum.sort_by(&(- Timex.DateTime.to_seconds(&1.updated_at)))

    conn
    |> assign(:route_alerts, route_alerts)
  end

  @doc """
  Fetches the full list of alerts from `conn.assigns` and assigns a filtered list
  of alerts for `stop_id`.
  """
  def stop_alerts(%{assigns: %{origin: nil}} = conn) do
    conn
    |> assign(:stop_alerts, nil)
  end
  def stop_alerts(%{assigns: %{origin: origin}} = conn) do
    stop_alerts = conn.assigns[:alerts]
    |> Alerts.Match.match(%Alerts.InformedEntity{stop: origin})

    conn
    |> assign(:stop_alerts, stop_alerts)
  end

  @doc """
  Fetches the full list of alerts from `conn.assigns` and assigns a filtered list
  of alerts for `stop_id`.
  """
  def trip_alerts(%{assigns: %{trip: nil}} = conn) do
    conn
    |> assign(:trip_alerts, nil)
  end
  def trip_alerts(%{assigns: %{trip: trip_id}} = conn) do
    trip_alerts = conn.assigns[:alerts]
    |> Alerts.Match.match(%Alerts.InformedEntity{trip: trip_id})

    conn
    |> assign(:trip_alerts, trip_alerts)
  end
end
