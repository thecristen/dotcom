defmodule Site.ScheduleController do
  use Site.Web, :controller
  use Timex

  def index(conn, %{"route" => route_id} = params) do
    date = case Timex.parse(params["date"], "{ISOdate}") do
             {:ok, value} -> value |> Date.from
             _ -> Date.today
           end

    direction_id = case params["direction_id"] do
                     nil -> 0
                     str -> String.to_integer(str)
                   end

    all_schedules = Schedules.Repo.all(
      route: route_id,
      date: date,
      direction_id: direction_id,
      stop_sequence: 1)

    show_all = params["all"] != nil || not Timex.equal?(Date.today, date)

    render(conn, "index.html",
      date: date,
      show_all_url: if show_all do
        nil
      else
        update_url(conn, all: "all")
      end,
      schedules: schedules(all_schedules, show_all),
      direction: direction(direction_id),
      route: route(all_schedules),
      from: from(all_schedules),
      to: to(all_schedules),
      reverse_url: update_url(conn,
        direction_id: reverse_direction(direction_id)))
  end

  def update_url(%{params: params} = conn, query) do
    query_map = query
    |> Enum.map(fn {key, value} -> {Atom.to_string(key), to_string(value)} end)
    |> Enum.into(%{})

    new_query = params
    |> Map.merge(query_map)
    |> Enum.into([])

    schedule_path(conn, :index, new_query)
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
    |> +(1)
    |> rem(2)
    |> Integer.to_string
  end

  defp most_frequent_value(values) do
    values
    |> Enum.group_by(&(&1))
    |> Enum.into([])
    |> Enum.max_by(fn {_, items} -> length(items) end)
    |> (fn {value, _} -> value end).()
  end
end
