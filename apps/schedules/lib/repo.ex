defmodule Schedules.Repo do
  import Kernel, except: [to_string: 1]

  def all(opts) do
    params = [
      include: "trip.route,stop,route",
      "fields[schedule]": "departure_time",
      "fields[stop]": "name",
      "fields[trip]": "name,headsign",
      "fields[route]": "type,long_name"
    ]
    params = params
    |> add_optional_param(opts, :route)
    |> add_optional_param(opts, :date)
    |> add_optional_param(opts, :direction_id)
    |> add_optional_param(opts, :stop_sequence)
    |> add_optional_param(opts, :stop)

    params
    |> V3Api.Schedules.all
    |> (fn api -> api.data end).()
    |> Enum.map(&Schedules.Parser.parse/1)
  end

  def stops(opts) do
    params = [
      include: "stop",
      "fields[schedule]": "stop_sequence",
      "fields[stop]": "name"
    ]
    params = params
    |> add_optional_param(opts, :route)
    |> add_optional_param(opts, :date)
    |> add_optional_param(opts, :direction_id)

    params
    |> V3Api.Schedules.all
    |> (fn api -> api.data end).()
    |> Enum.map(&Schedules.Parser.stop/1)
    |> Enum.uniq
    |> Enum.sort_by(fn stop -> stop.name end)
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
