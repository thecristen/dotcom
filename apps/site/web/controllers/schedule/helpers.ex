defmodule Site.ScheduleController.Helpers do
  import Plug.Conn
  import Site.Router.Helpers
  import Util
  use Timex

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
  def assign_all_stops(conn, "Red" = route_id) do
    conn
    |> assign(:all_stops, Enum.uniq_by(get_all_stops(conn, route_id), &(&1.id)))
  end
  def assign_all_stops(conn, route_id) do
    conn
    |> assign(:all_stops, get_all_stops(conn, route_id))
  end

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

  @braintree_stops [
    "place-brntn",
    "place-qamnl",
    "place-qnctr",
    "place-wlsta",
    "place-nqncy"
  ]
  @ashmont_stops [
    "place-asmnl",
    "place-smmnl",
    "place-fldcr",
    "place-shmnl"
  ]

  @doc """
  Fetch applicable destination stops for the given route. If no origin is set then we don't need
  destinations yet. If the route is northbound on the red line coming from the Ashmont or Braintree
  branches, filter out stops on the opposite branch. For all other routes, the already assigned
  :all_stops is sufficient.
  """
  def assign_destination_stops(%{assigns: %{origin: nil}} = conn, _) do
    conn
  end
  def assign_destination_stops(conn, "Red") do
    all_stops = conn.assigns[:all_stops]
    northbound = conn.assigns[:direction_id] == 1
    origin = conn.assigns[:origin]
    filtered_stops = cond do
      northbound and origin in @braintree_stops ->
        Enum.reject(all_stops, &(&1.id in @ashmont_stops))
      northbound and origin in @ashmont_stops ->
        Enum.reject(all_stops, &(&1.id in @braintree_stops))
      true ->
        all_stops
    end
    conn
    |> assign(:destination_stops, filtered_stops)
  end
  def assign_destination_stops(conn, _) do
    conn
    |> assign(:destination_stops, conn.assigns[:all_stops])
  end

  defp get_all_stops(conn, route_id) do
    Schedules.Repo.stops(
      route_id,
      direction_id: conn.assigns[:direction_id]
    )
  end

  @doc """
  Once @route is set, fetches all the routes with that same type and assigns them
  as @all_routes
  """
  def assign_all_routes(%{assigns: %{route: %{type: type}}} = conn) do
    type = if type in [0, 1] do
      [0, 1]
    else
      type
    end

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
    {all_schedules, assign(conn, :show_all, true)}
  end
  def possibly_open_schedules(schedules, _, conn) do
    {schedules, conn}
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
    |> assign(:breadcrumbs, [{schedule_path(conn, :index), "Schedules & Maps"}, route_type_display, name])
  end
end
