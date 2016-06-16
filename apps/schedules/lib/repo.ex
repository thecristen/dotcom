defmodule Schedules.Repo do
  import Kernel, except: [to_string: 1]
  use RepoCache, ttl: :timer.hours(24)

  @default_params [
      include: "trip.route,stop",
      "fields[schedule]": "departure_time",
      "fields[stop]": "name"
  ]
  def all(opts) do
    params = Keyword.merge(@default_params, [
          "fields[trip]": "name,headsign",
          "fields[route]": "type,long_name,short_name"
        ])
    params
    |> add_optional_param(opts, :route)
    |> add_optional_param(opts, :date)
    |> add_optional_param(opts, :direction_id)
    |> add_optional_param(opts, :stop_sequence)
    |> add_optional_param(opts, :stop)
    |> cache(fn(params) ->
      params
      |> all_from_params
      |> Enum.sort_by(fn schedule -> schedule.time end)
    end)
  end

  def stops(opts) do
    params = [
      include: "stop",
      "fields[schedule]": "",
      "fields[stop]": "name"
    ]
    params = params
    |> add_optional_param(opts, :route)
    |> add_optional_param(opts, :date)
    |> add_optional_param(opts, :direction_id)

    params
    |> cache(fn params ->
      params
      |> V3Api.Schedules.all
      |> (fn api -> api.data end).()
      |> Enum.map(&Schedules.Parser.stop/1)
      |> uniq_by_last_appearance
    end)
  end

  def trip(trip_id) do
    @default_params
    |> Keyword.merge([
      trip: trip_id
    ])
    |> cache(&all_from_params/1)
  end

  def origin_destination(origin_stop, dest_stop, opts \\ []) do
    {origin_stop, dest_stop, opts}
    |> cache(fn _ ->
      origin_task = Task.async(Schedules.Repo, :schedule_for_stop, [origin_stop, opts])
      dest_task = Task.async(Schedules.Repo, :schedule_for_stop, [dest_stop, opts])

      {:ok, origin_stops} = Task.yield(origin_task)
      {:ok, dest_stops} = Task.yield(dest_task)

      origin_stops
      |> Join.join(dest_stops, fn schedule -> schedule.trip.id end)
      |> Enum.filter(fn {o, d} -> o.time < d.time end) # filter out reverse trips
    end)
  end

  def schedule_for_stop(stop_id, opts) do
    opts
    |> Keyword.merge([
      stop: stop_id
    ])
    |> all
    |> Enum.sort_by(fn schedule -> schedule.time end)
  end

  defp all_from_params(params) do
    params
    |> V3Api.Schedules.all
    |> (fn api -> api.data end).()
    |> Enum.map(&Schedules.Parser.parse/1)
  end

  defp add_optional_param(params, opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, value} ->
        params
        |> Keyword.put(key, to_string(value))
      :error ->
        params
    end
  end

  defp to_string(%Timex.Date{} = date) do
    date
    |> Timex.format!("{ISOdate}")
  end
  defp to_string(str) when is_binary(str) do
    str
  end
  defp to_string(other) do
    Kernel.to_string(other)
  end

  defp uniq_by_last_appearance(items) do
    # We get multiple copies of the stops, based on the order they are in
    # various schedules. A stop can appear multiple times, and we want to
    # take the last place the stop appears.  We take advantage of Enum.uniq/1
    # keeping the first time an item appears: we reverse the list to have it
    # keep the last time, then re-reverse the list.
    items
    |> Enum.reverse
    |> Enum.uniq
    |> Enum.reverse
  end
end
