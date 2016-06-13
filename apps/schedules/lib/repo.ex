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
      "fields[schedule]": "",
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
    |> uniq_by_last_appearance
  end

  def trip(trip_id) do
    params = [
      include: "stop,trip.route",
      "fields[schedule]": "departure_time",
      "fields[stop]": "name",
      trip: trip_id
    ]
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
