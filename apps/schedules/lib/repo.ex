defmodule Schedules.Repo do
  import Kernel, except: [to_string: 1]
  use RepoCache, ttl: :timer.hours(24)

  alias Schedules.Schedule
  alias Stops.Stop

  @type schedule_pair :: {Schedule.t, Schedule.t}

  @default_timeout 10_000
  @default_params [
      include: "trip,route",
      "fields[schedule]": "departure_time,drop_off_type,pickup_type,stop_sequence",
      "fields[trip]": "name,headsign,direction_id",
      "fields[stop]": "name"
  ]

  @spec by_route_ids([String.t], Keyword.t) :: [Schedule.t] | {:error, any}
  def by_route_ids(route_ids, opts \\ []) when is_list(route_ids) do
    @default_params
    |> Keyword.put(:route, Enum.join(route_ids, ","))
    |> add_optional_param(opts, :date)
    |> add_optional_param(opts, :direction_id)
    |> add_optional_param(opts, :stop_sequences, :stop_sequence)
    |> add_optional_param(opts, :stop_ids, :stop)
    |> cache(&all_from_params/1)
  end

  @spec schedule_for_trip(Schedules.Trip.id_t, Keyword.t) :: [Schedule.t] | {:error, any}
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
    |> Keyword.put_new(:date, Util.service_date)
    |> cache(&all_from_params/1)
  end

  @spec origin_destination(Stop.id_t, Stop.id_t, Keyword.t) :: [schedule_pair] | {:error, any}
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
    end, timeout: @default_timeout)
  end

  @spec schedule_for_stop(Stop.id_t, Keyword.t) :: [Schedule.t] | {:error, any}
  def schedule_for_stop(stop_id, opts) do
    @default_params
    |> Keyword.merge(opts)
    |> Keyword.put(:stop, stop_id)
    |> cache(&all_from_params/1)
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
      data
      |> Enum.map(&Schedules.Parser.parse/1)
      |> Enum.sort_by(&DateTime.to_unix(&1.time))
    end
  end

  defp add_optional_param(params, opts, key, param_name \\ nil) do
    param_name = param_name || key
    case Keyword.fetch(opts, key) do
      {:ok, value} ->
        Keyword.put(params, param_name, to_string(value))
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
  defp to_string(atom) when is_atom(atom) do
    Atom.to_string(atom)
  end
  defp to_string(list) when is_list(list) do
    list
    |> Enum.map(&to_string/1)
    |> Enum.join(",")
  end
  defp to_string(int) when is_integer(int) do
    Integer.to_string(int)
  end

  defp join_schedules(origin_schedules, dest_schedules) do
    origin_schedules
    |> Join.join(dest_schedules, & &1.trip.id)
    |> Enum.filter(fn {o, d} -> o.stop_sequence < d.stop_sequence end)
    |> Enum.uniq_by(fn {o, _} -> o.trip.id end)
  end
end
