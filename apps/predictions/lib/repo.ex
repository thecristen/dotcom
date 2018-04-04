defmodule Predictions.Repo do
  use RepoCache, ttl: :timer.seconds(10), ttl_check: :timer.seconds(2)
  require Logger
  alias Stops.Stop

  @default_params [
    "fields[prediction]": "track,status,departure_time,arrival_time,direction_id,schedule_relationship,stop_sequence",
    "fields[trip]": "direction_id,headsign,name",
    "include": "trip"
  ]

  def all(opts) when is_list(opts) and opts != [] do
    @default_params
    |> add_optional_param(opts, :route)
    |> add_optional_param(opts, :stop)
    |> add_optional_param(opts, :direction_id)
    |> add_optional_param(opts, :trip)
    |> cache(&fetch/1)
    |> load_from_other_repos
  end

  defp add_optional_param(params, opts, key) do
    case Keyword.get(opts, key) do
      nil -> params
      value -> Keyword.put(params, key, value)
    end
  end

  defp fetch(params) do
    case V3Api.Predictions.all(params) do
      {:error, error} -> warn_error(params, error)
      %JsonApi{data: data} ->
        Schedules.Repo.insert_trips_into_cache(data)
        Enum.flat_map(data, &parse/1)
    end
  end

  defp parse(item) do
    try do
      [Predictions.Parser.parse(item)]
    rescue
      e -> warn_error(item, e)
    end
  end

  defp warn_error(item, e) do
    _ = Logger.warn("error during Prediction (#{inspect item}): #{inspect e}")
    []
  end

  def load_from_other_repos([]) do
    []
  end
  def load_from_other_repos(predictions) do
    predictions
    |> Task.async_stream(&record_to_structs/1)
    |> Enum.flat_map(fn {:ok, prediction} -> prediction end)
  end

  defp record_to_structs({_, _, nil, _, _, _, _, _, _, _, _}) do
    # no stop ID
    []
  end
  defp record_to_structs({_, _, <<stop_id::binary>>, _, _, _, _, _, _, _, _} = record) do
    stop_id
    |> Stops.Repo.get()
    |> do_record_to_structs(record)
  end

  defp do_record_to_structs(nil, {_, _, <<stop_id::binary>>, _, _, _, _, _, _, _, _} = record) do
    :ok = Logger.error("Discarding prediction because stop #{inspect(stop_id)} does not exist. Prediction: #{inspect(record)}")
    []
  end
  defp do_record_to_structs(%Stop{} = stop, {
      id,
      trip_id,
      _stop_id,
      route_id,
      direction_id,
      time,
      stop_sequence,
      schedule_relationship,
      track,
      status,
      departing?}) do

    trip = if trip_id do
      Schedules.Repo.trip(trip_id)
    end
    route = Routes.Repo.get(route_id)
    [
      %Predictions.Prediction{
        id: id,
        trip: trip,
        stop: stop,
        route: route,
        direction_id: direction_id,
        time: time,
        stop_sequence: stop_sequence,
        schedule_relationship: schedule_relationship,
        track: track,
        status: status,
        departing?: departing?}
    ]
  end
end
