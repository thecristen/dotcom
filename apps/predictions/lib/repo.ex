defmodule Predictions.Repo do
  use RepoCache, ttl: :timer.seconds(10)

  @default_params [
    "fields[prediction]": "track,status,departure_time,arrival_time"
  ]

  def all(opts) when is_list(opts) and opts != [] do
    @default_params
    |> add_optional_param(opts, :route)
    |> add_optional_param(opts, :stop)
    |> add_optional_param(opts, :direction_id)
    |> cache(fn(params) ->
      params
      |> V3Api.Predictions.all
      |> Map.get(:data)
      |> Enum.map(&Predictions.Parser.parse/1)
    end)
  end

  defp add_optional_param(params, opts, key) do
    case Keyword.get(opts, key) do
      nil -> params
      value -> Keyword.put(params, key, value)
    end
  end
end
