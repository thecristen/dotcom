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

  def stops(route, opts) do
    params = [
      route: route,
      "fields[stop]": "name"
    ]
    params = params
    |> add_optional_param(opts, :direction_id)
    |> add_optional_param(opts, :date)

    params
    |> cache(fn params ->
      params
      |> V3Api.Stops.all
      |> (fn api -> api.data end).()
      |> Enum.map(&(%Schedules.Stop{id: &1.id, name: &1.attributes["name"]}))
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
end
