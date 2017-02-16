defmodule Predictions.Repo do
  use RepoCache, ttl: :timer.seconds(10)
  require Logger

  @default_params [
    "fields[prediction]": "track,status,departure_time,arrival_time,direction_id,schedule_relationship",
    "fields[stop]": "",
    "fields[trip]": "direction_id,headsign,name",
    "include": "stop,trip,route"
  ]

  def all(opts) when is_list(opts) and opts != [] do
    @default_params
    |> add_optional_param(opts, :route)
    |> add_optional_param(opts, :stop)
    |> add_optional_param(opts, :direction_id)
    |> add_optional_param(opts, :trip)
    |> cache(&fetch/1)
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
      %JsonApi{data: data} -> Enum.flat_map(data, &parse/1)
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
end
