defmodule Site.ScheduleController do
  use Site.Web, :controller
  use Timex

  def index(conn, %{"origin" => origin_id, "dest" => dest_id} = params) do
    default_params = index_params(params)
    opts = []
    |> Dict.put(:direction_id, default_direction_id(params))
    |> Dict.put(:date, default_date(params))

    pairs = Schedules.Repo.origin_destination(origin_id, dest_id, opts)
    render(conn, "pairs.html", Keyword.merge(default_params, [
              from: pairs |> List.first |> (fn {x, _} -> x.stop.name end).(),
              to: pairs |> List.first |> (fn {_, y} -> y.stop.name end).(),
              pairs: pairs
            ]))
  end

  def index(conn, %{"route" => route_id} = params) do
    default_params = index_params(params)

    date = default_params[:date]
    direction_id = default_direction_id(params)
    trip = params
    |> Map.get("trip", "")


    basic_schedule_params = [
      route: route_id,
      date: date,
      direction_id: direction_id]

    basic_schedule_params = case Map.get(params, "origin", "") do
                              "" -> basic_schedule_params
                              |> Keyword.put(:stop_sequence, 1)
                              value -> basic_schedule_params
                              |> Keyword.put(:stop, value)
                            end
    [all_schedules, all_stops, alerts, trip_schedule] = AsyncList.run([
      {Schedules.Repo, :all, [basic_schedule_params]},
      {Schedules.Repo, :stops, [[
                                 route: route_id,
                                 date: date,
                                 direction_id: direction_id]]},
      {Alerts.Repo, :all, []},
      {Site.ScheduleController, :selected_trip, [trip]}])

    filtered_schedules = schedules(all_schedules, default_params[:show_all])
    {filtered_schedules, default_params} = if filtered_schedules == [] do
      {all_schedules, Keyword.put(default_params, :show_all, true)}
    else
      {filtered_schedules, default_params}
    end

    render(conn, "index.html", Keyword.merge(default_params, [
              all_stops: all_stops,
              schedules: filtered_schedules,
              route: route(all_schedules),
              from: from(all_schedules),
              to: to(all_schedules),
              alerts: alerts,
              trip: trip,
              trip_schedule: trip_schedule
            ]))

  end

  def index_params(params) do
    date = default_date(params)

    direction_id = default_direction_id(params)

    show_all = params["all"] != nil || not Timex.equal?(Date.today, date)

    [
      date: date,
      show_all: show_all,
      direction: direction(direction_id),
      reverse_direction_id: reverse_direction_id(direction_id),
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

  def schedules(all_schedules, show_all)
  def schedules(all_schedules, true) do
    all_schedules
    |> sort_schedules
  end
  def schedules(all_schedules, false) do
    default_schedules = schedules(all_schedules, true)

    first_after_index = default_schedules
    |> Enum.find_index(fn %{time: time} ->
      time
      |> Timex.after?(DateTime.now)
    end)

    if first_after_index == nil do
      []
    else
      all_schedules
      |> Enum.drop(first_after_index - 1)
    end
  end

  defp sort_schedules(all_schedules) do
    all_schedules
    |> Enum.sort_by(fn schedule -> schedule.time end)
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
    |> Integer.to_string
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
