defmodule Site.ScheduleController do
  use Site.Web, :controller
  use Timex

  def index(conn, %{"route" => route_id} = params) do
    date = case Timex.parse(params["date"], "{ISOdate}") do
             {:ok, value} -> value |> Date.from
             _ -> Date.today
           end

    direction_id = case params["direction_id"] do
                     nil -> default_direction_id
                     str -> String.to_integer(str)
                   end

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

    show_all = params["all"] != nil || not Timex.equal?(Date.today, date)

    render(conn, "index.html",
      date: date,
      show_all: show_all,
      schedules: schedules(all_schedules, show_all),
      all_stops: all_stops,
      direction: direction(direction_id),
      reverse_direction: reverse_direction(direction_id),
      route: route(all_schedules),
      from: from(all_schedules),
      to: to(all_schedules),
      origin: params["origin"],
      trip: trip,
      trip_schedule: trip_schedule,
      alerts: alerts)
  end

  def default_direction_id do
    if DateTime.now("America/New_York").hour <= 13 do
      1 # Inbound
    else
      0
    end
  end

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

    all_schedules
    |> Enum.drop(first_after_index - 1)
  end

  defp sort_schedules(all_schedules) do
    all_schedules
    |> Enum.sort_by(fn schedule -> schedule.time end)
  end

  def direction(0), do: "Outbound"
  def direction(1), do: "Inbound"
  def direction(_), do: "Unknown"

  def route(all_schedules) do
    all_schedules
    |> List.first
    |> (fn schedule -> schedule.route end).()
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

  def reverse_direction(direction_id) do
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
