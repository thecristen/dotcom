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

    all_schedules = Schedules.Repo.all(
      route: route,
      date: date,
      direction_id: direction_id,
      stop_sequence: 1)
    show_all = params["all"] != nil

    render(conn, "index.html",
      date: date,
      show_all_url: case show_all do
                      false ->
                        schedule_path(conn, :index,
                          route: route,
                          direction_id: direction_id |> Integer.to_string,
                          all: "all")
                      true ->
                        nil
                    end,
      schedules: schedules(all_schedules, show_all),
      direction: direction(direction_id),
      route: route(all_schedules),
      from: from(all_schedules),
      to: to(all_schedules),
      reverse_url: schedule_path(conn, :index,
        route: route,
        direction_id: rem(direction_id + 1, 2) |> Integer.to_string))
  end

  def schedules(all_schedules, true) do
    all_schedules
  end
  def schedules(all_schedules, false) do
    all_schedules
    |> Enum.drop_while(fn %{time: time} ->
      Timex.after?(DateTime.now, time)
    end)
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
