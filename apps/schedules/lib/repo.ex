defmodule Schedules.Repo do
  import Kernel, except: [to_string: 1]
  use RepoCache, ttl: :timer.hours(24)

  @type schedule_pair :: {Schedules.Schedule.t, Schedules.Schedule.t}

  @default_timeout 10_000
  @default_params [
      include: "trip,route,stop.parent_station",
      "fields[schedule]": "departure_time,drop_off_type,pickup_type,stop_sequence",
      "fields[trip]": "name,headsign,direction_id",
      "fields[stop]": "name"
  ]

  @spec all(Keyword.t) :: [Schedules.Schedule.t] | {:error, any}
  def all(opts) do
    @default_params
    |> add_optional_param(opts, :route)
    |> add_optional_param(opts, :date)
    |> add_optional_param(opts, :direction_id)
    |> add_optional_param(opts, :stop_sequence)
    |> add_optional_param(opts, :stop)
    |> cache(fn(params) ->
      with schedules when is_list(schedules) <- all_from_params(params) do
        Enum.sort_by(schedules, &DateTime.to_unix(&1.time))
      end
    end)
  end

  @spec schedule_for_trip(Schedules.Trip.id_t, Keyword.t) :: [Schedules.Schedule.t] | {:error, any}
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

  @spec origin_destination(Stops.Stop.id_t, Stops.Stop.id_t, Keyword.t) :: [schedule_pair] | {:error, any}
  def origin_destination(origin_stop, dest_stop, opts \\ []) do
    {origin_stop, dest_stop, opts}
    |> cache(fn _ ->
      origin_task = Task.async(__MODULE__, :schedule_for_stop, [origin_stop, opts])
      dest_task = Task.async(__MODULE__, :schedule_for_stop, [dest_stop, opts])
      {:ok, origin} = Task.yield(origin_task, @default_timeout)
      {:ok, dest} = Task.yield(dest_task, @default_timeout)

      with origin when is_list(origin) <- origin,
           dest when is_list(dest) <- dest do
        join_schedules(origin, dest)
      end
    end)
  end

  @spec schedule_for_stop(Stops.Stop.id_t, Keyword.t) :: [Schedules.Schedule.t] | {:error, any}
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

  @spec end_of_rating() :: Date.t | nil
  def end_of_rating(all_fn \\ &V3Api.Schedules.all/1) do
    cache all_fn, fn all_fn ->
      with {:error, [%{code: "no_service"} = error]} <- all_fn.(route: "Red", date: "1970-01-01"),
           {:ok, date} <- Timex.parse(error.meta["end_date"], "{ISOdate}") do
        NaiveDateTime.to_date(date)
      else
        _ -> nil
      end
    end
  end

  defp all_from_params(params) do
    with %JsonApi{data: data} <- V3Api.Schedules.all(params) do
      Enum.map(data, &Schedules.Parser.parse/1)
    end
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

  defp join_schedules(origin_schedules, dest_schedules) do
    origin_schedules
    |> Join.join(dest_schedules, & &1.trip.id)
    |> Enum.filter(fn {o, d} -> o.stop_sequence < d.stop_sequence end)
    |> Enum.uniq_by(fn {o, _} -> o.trip.id end)
  end
end
