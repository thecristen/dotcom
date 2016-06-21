defmodule Site.ScheduleController do
  use Site.Web, :controller
  use Timex
  import Plug.Conn

  def index(conn, %{"origin" => origin_id, "dest" => dest_id} = params) do
    conn = conn
    |> default_assigns
    |> async_alerts

    opts = []
    |> Dict.put(:direction_id, default_direction_id(params))
    |> Dict.put(:date, default_date(params))

    pairs = Schedules.Repo.origin_destination(origin_id, dest_id, opts)

    general_route = pairs
    |> Enum.map(fn {stop, _} -> stop.route end)
    |> most_frequent_value

    {filtered_pairs, conn} = pairs
    |> Enum.filter(fn {_, dest} -> is_after_now?(dest) end)
    |> possibly_open_schedules(pairs, conn)

    conn
    |> assign(:route, general_route)
    |> async_all_routes
    |> await_assign_all
    |> render("pairs.html",
      from: pairs |> List.first |> (fn {x, _} -> x.stop.name end).(),
      to: pairs |> List.first |> (fn {_, y} -> y.stop.name end).(),
      pairs: filtered_pairs
    )
  end

  def index(conn, %{"route" => route_id}) do
    conn = conn
    |> default_assigns
    |> async_alerts
    |> async_all_stops(route_id)
    |> async_selected_trip

    all_schedules = conn
    |> basic_schedule_params
    |> Schedules.Repo.all

    {filtered_schedules, conn} = all_schedules
    |> schedules(conn.assigns[:show_all])
    |> possibly_open_schedules(all_schedules, conn)

    conn
    |> assign(:route, route(all_schedules))
    |> async_all_routes
    |> assign(:schedules, filtered_schedules)
    |> assign(:from, from(all_schedules))
    |> assign(:to, to(all_schedules))
    |> assign_list_group_template
    |> await_assign_all
    |> render("index.html")
  end

  def assign_list_group_template(%{assigns: %{route: %{type: type}}} = conn) do
    list_group_template = case type do
                            0 ->
                              "subway.html"
                            1 ->
                              "subway.html"
                            3 ->
                              "bus.html"
                            _ ->
                              "rail.html"
                          end

    conn
    |> assign(:list_group_template, list_group_template)
  end

  def default_assigns(conn) do
    conn.params
    |> index_params
    |> Enum.reduce(conn, fn {key, value}, conn -> assign(conn, key, value) end)
  end

  def async_alerts(conn) do
    conn
    |> async_assign(:alerts, &Alerts.Repo.all/0)
  end

  def async_all_stops(conn, route_id) do
    conn
    |> async_assign(:all_stops, fn ->
      Schedules.Repo.stops(
        route: route_id,
        date: conn.assigns[:date],
        direction_id: conn.assigns[:direction_id])
    end)
  end

  def async_all_routes(%{assigns: %{route: %{type: type}}} = conn) do
    conn
    |> async_assign(:all_routes, fn ->
      Routes.Repo.by_type(type)
    end)
  end

  def async_selected_trip(%{params: %{"trip" => trip_id}} = conn) do
    conn
    |> assign(:trip, trip_id)
    |> async_assign(:trip_schedule, fn ->
      selected_trip(trip_id)
    end)
  end
  def async_selected_trip(conn) do
    conn
    |> assign(:trip, nil)
  end

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

  def index_params(params) do
    date = default_date(params)

    direction_id = default_direction_id(params)

    show_all = params["all"] != nil || not Timex.equal?(Date.today, date)

    [
      date: date,
      show_all: show_all,
      direction_id: direction_id,
      direction: direction(direction_id),
      reverse_direction_id: reverse_direction_id(direction_id),
      reverse_direction: direction(reverse_direction_id(direction_id)),
      origin: params["origin"],
      destination: params["dest"],
    ]
  end

  def default_date(params) do
    case Timex.parse(params["date"], "{ISOdate}") do
      {:ok, value} -> value |> Date.from
      _ -> Date.today
    end
  end

  def default_direction_id(params) do
    case params["direction_id"] do
      nil ->
        if DateTime.now("America/New_York").hour <= 13 do
          1 # Inbound
        else
          0
        end

      str ->
        String.to_integer(str)
    end
  end

  def basic_schedule_params(%{params: params, assigns: assigns}) do
    schedule_params = [
      route: params["route"],
      date: assigns[:date],
      direction_id: assigns[:direction_id]]

    case Map.get(params, "origin", "") do
      "" -> schedule_params
      |> Keyword.put(:stop_sequence, 1)

      value -> schedule_params
      |> Keyword.put(:stop, value)
    end
  end


  def schedules(all_schedules, show_all)
  def schedules(all_schedules, true) do
    all_schedules
    |> sort_schedules
  end
  def schedules(all_schedules, false) do
    default_schedules = schedules(all_schedules, true)

    first_after_index = default_schedules
    |> Enum.find_index(&is_after_now?/1)

    if first_after_index == nil do
      []
    else
      all_schedules
      |> Enum.drop(first_after_index - 1)
    end
  end

  def possibly_open_schedules([], all_schedules, conn) do
    { all_schedules, assign(conn, :show_all, true) }
  end
  def possibly_open_schedules(schedules, _, conn) do
    { schedules, conn }
  end

  defp sort_schedules(all_schedules) do
    all_schedules
    |> Enum.sort_by(fn schedule -> schedule.time end)
  end

  defp is_after_now?(%{time: time}) do
    time
    |> Timex.after?(DateTime.now)
  end

  def direction(0), do: "Outbound"
  def direction(1), do: "Inbound"
  def direction(_), do: "Unknown"

  def route([schedule|_]) do
    schedule.route
  end

  def from(all_schedules) do
    all_schedules
    |> Enum.map(fn schedule -> schedule.stop.name end)
    |> most_frequent_value
  end

  def to(all_schedules) do
    all_schedules
    |> Enum.map(fn schedule -> schedule.trip.headsign end)
    |> most_frequent_value
  end

  def reverse_direction_id(direction_id) do
    direction_id
    |> Kernel.+(1)
    |> rem(2)
  end

  def selected_trip("") do
    nil
  end
  def selected_trip(trip_id) do
    Schedules.Repo.trip(trip_id)
  end

  defp most_frequent_value(values) do
    values
    |> Enum.group_by(&(&1))
    |> Enum.into([])
    |> Enum.max_by(fn {_, items} -> length(items) end)
    |> (fn {value, _} -> value end).()
  end
end
