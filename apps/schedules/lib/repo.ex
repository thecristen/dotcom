defmodule Schedules.Repo do
  import Kernel, except: [to_string: 1]
  use RepoCache, ttl: :timer.hours(24)

  @default_timeout 10_000
  @default_params [
      include: "trip,route,stop.parent_station",
      "fields[schedule]": "departure_time,drop_off_type,pickup_type,stop_sequence",
      "fields[trip]": "name,headsign,direction_id",
      "fields[stop]": "name"
  ]

  def all(opts) do
    @default_params
    |> add_optional_param(opts, :route)
    |> add_optional_param(opts, :date)
    |> add_optional_param(opts, :direction_id)
    |> add_optional_param(opts, :stop_sequence)
    |> add_optional_param(opts, :stop)
    |> cache(fn(params) ->
      params
      |> all_from_params
      |> Enum.sort_by(fn schedule -> DateTime.to_unix(schedule.time) end)
    end)
  end

  @spec schedule_for_trip(Schedules.Trip.id_t, Keyword.t) :: [Schedules.Schedule.t]
  def schedule_for_trip(trip_id, opts \\ [])
  def schedule_for_trip("", _) do
    # shortcut a known invalid trip ID
    []
  end
  def schedule_for_trip(trip_id, opts) do
    @default_params
    |> Keyword.merge(opts)
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

      {:ok, origin_stops} = Task.yield(origin_task, @default_timeout)
      {:ok, dest_stops} = Task.yield(dest_task, @default_timeout)

      origin_stops
      |> Join.join(dest_stops, fn schedule -> schedule.trip.id end)
      |> Enum.filter(fn {o, d} -> Timex.before?(o.time, d.time) end) # filter out reverse trips
      |> Enum.uniq_by(fn {o, _} -> o.trip.id end)
    end)
  end

  def schedule_for_stop(stop_id, opts) do
    opts
    |> Keyword.merge([
      stop: stop_id
    ])
    |> all
  end

  @spec trip(String.t) :: Schedules.Trip.t | nil
  def trip(trip_id) do
    cache trip_id, fn trip_id ->
      case V3Api.Trips.by_id(trip_id) do
        {:error, _} -> nil
        response -> Schedules.Parser.trip(response)
      end
    end
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

  defp to_string(%Date{} = date) do
    date
    |> Timex.format!("{ISOdate}")
  end
  defp to_string(str) when is_binary(str) do
    str
  end
  defp to_string(other) do
    Kernel.to_string(other)
  end
end
