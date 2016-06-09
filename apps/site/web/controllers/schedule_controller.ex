defmodule Site.ScheduleController do
  use Site.Web, :controller
  use Timex

  def index(conn, %{"route" => route} = params) do
    date = case Timex.parse(params["date"], "{ISOdate}") do
             {:ok, value} -> value
             _ -> Date.today
           end

    direction_id = case params["direction_id"] do
                     nil -> 0
                     str -> String.to_integer(str)
                   end

    schedules = Schedules.Repo.all(
      route: route,
      date: date,
      direction_id: direction_id,
      stop_sequence: 1)

    render(conn, "index.html",
      date: date,
      schedules: schedules,
      direction: direction(direction_id),
      route: route(schedules),
      from: from(schedules),
      to: to(schedules),
      reverse_url: schedule_path(conn, :index,
        route: route,
        direction_id: rem(direction_id + 1, 2) |> Integer.to_string))
  end

  def direction(0), do: "Outbound"
  def direction(1), do: "Inbound"
  def direction(_), do: "Unknown"

  def route(schedules) do
    schedules
    |> List.first
    |> (fn schedule -> schedule.route end).()
  end

  def from(schedules) do
    schedules
    |> Enum.map(fn schedule -> schedule.stop.name end)
    |> most_frequent_value
  end

  def to(schedules) do
    schedules
    |> Enum.map(fn schedule -> schedule.trip.headsign end)
    |> most_frequent_value
  end

  defp most_frequent_value(values) do
    values
    |> Enum.group_by(&(&1))
    |> Enum.into([])
    |> Enum.max_by(fn {_, items} -> length(items) end)
    |> (fn {value, _} -> value end).()
  end
end
