defmodule TripPlan.Query do
  alias TripPlan.{Itinerary, Geocode}

  @enforce_keys [:from, :to, :itineraries]
  defstruct [:from, :to, :itineraries]

  @type t :: %__MODULE__{
    from: Geocode.t,
    to: Geocode.t,
    itineraries: {:ok, [Itinerary.t]} | {:error, any}
  }

  def from_query(%{"from" => from, "to" => to} = query) do
    from = TripPlan.geocode(from)
    to = TripPlan.geocode(to)
    itineraries = with {:ok, opts} <- opts_from_query(query),
                       {:ok, from} <- from,
                       {:ok, to} <- to do
                    TripPlan.plan(from, to, opts)
                  end
    %__MODULE__{
      from: from,
      to: to,
      itineraries: itineraries
    }
  end

  defp opts_from_query(query, opts \\ [])
  defp opts_from_query(%{"time" => "depart", "date_time" => _date_time} = query, opts) do
    do_date_time(:depart_at, query, opts)
  end
  defp opts_from_query(%{"time" => "arrive", "date_time" => _date_time} = query, opts) do
    do_date_time(:arrive_by, query, opts)
  end
  defp opts_from_query(%{"include_car?" => "true"} = query, opts) do
    opts_from_query(
      Map.delete(query, "include_car?"),
      Keyword.put(opts, :personal_mode, :drive)
    )
  end
  defp opts_from_query(%{"accessible" => "true"} = query, opts) do
    opts_from_query(
      Map.delete(query, "accessible"),
      Keyword.put(opts, :wheelchair_accessible?, true)
    )
  end
  defp opts_from_query(_, opts) do
      {:ok, opts}
  end

  defp do_date_time(param, %{"date_time" => date_time} = query, opts) do
    case cast_datetime(date_time) do
      {:ok, dt} ->
        opts_from_query(
          Map.drop(query, ["time", "date_time"]),
          Keyword.put(opts, param, dt))
      error ->
        error
    end
  end

  defp cast_datetime(%{"year" => y, "month" => month, "day" => d, "hour" => h, "minute" => minute}) do
    with {y, ""} <- Integer.parse(y),
         {month, ""} <- Integer.parse(month),
         {d, ""} <- Integer.parse(d),
         {h, ""} <- Integer.parse(h),
         {minute, ""} <- Integer.parse(minute) do
      {:ok, Timex.to_datetime({{y, month, d}, {h, minute, 0}}, "America/New_York")}
    else
      _ -> {:error, :invalid}
    end
  end
end
