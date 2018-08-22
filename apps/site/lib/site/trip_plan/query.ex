defmodule Site.TripPlan.Query do
  alias TripPlan.{Itinerary, NamedPosition}

  defstruct [:from,
             :to,
             :itineraries,
             errors: MapSet.new(),
             time: :unknown,
             wheelchair_accessible?: false]

  @type position_error :: TripPlan.Geocode.error | :same_address
  @type position :: NamedPosition.t | {:error, position_error} | nil
  @type t :: %__MODULE__{
    from: position,
    to: position,
    time: :unknown | {:depart_at | :arrive_by, DateTime.t},
    errors: MapSet.t(atom),
    wheelchair_accessible?: boolean,
    itineraries: TripPlan.Api.t | nil
  }

  @spec from_query(map) :: t
  def from_query(params) do
    opts = opts_from_query(params)

    %__MODULE__{}
    |> Site.TripPlan.Location.validate(params)
    |> include_options(opts)
    |> maybe_fetch_itineraries(opts)
  end

  @spec maybe_fetch_itineraries(t, Keyword.t) :: t
  defp maybe_fetch_itineraries(%__MODULE__{
    to: %NamedPosition{},
    from: %NamedPosition{}
  } = query, opts) do
    if Enum.empty?(query.errors) do
      query
      |> fetch_itineraries(opts)
      |> parse_itinerary_result(query)
    else
      query
    end
  end
  defp maybe_fetch_itineraries(%__MODULE__{} = query, _opts) do
    query
  end

  @spec fetch_itineraries(t, Keyword.t) :: TripPlan.Api.t
  defp fetch_itineraries(%__MODULE__{from: %NamedPosition{} = from, to: %NamedPosition{} = to}, opts) do
    if Keyword.get(opts, :wheelchair_accessible?) do
      TripPlan.plan(from, to, opts)
    else
      accessible_opts = Keyword.put(opts, :wheelchair_accessible?, true)

      [mixed_results, accessible_results] = Util.async_with_timeout([
        fn -> TripPlan.plan(from, to, opts) end,
        fn -> TripPlan.plan(from, to, accessible_opts) end,
      ], {:error, :timeout})

      dedup_itineraries(mixed_results, accessible_results)
    end
  end

  @spec parse_itinerary_result(TripPlan.Api.t, t) :: t
  defp parse_itinerary_result({:ok, _} = result, %__MODULE__{} = query) do
    %{query | itineraries: result}
  end
  defp parse_itinerary_result({:error, error}, %__MODULE__{} = query) do
    query
    |> Map.put(:itineraries, {:error, error})
    |> Map.put(:errors, MapSet.put(query.errors, error))
  end

  @spec dedup_itineraries(TripPlan.Api.t, TripPlan.Api.t) :: TripPlan.Api.t
  defp dedup_itineraries({:error, _status} = response, {:error, _accessible_response}), do: response
  defp dedup_itineraries(unknown, {:error, _response}), do: unknown
  defp dedup_itineraries({:error, _response}, {:ok, _itineraries} = accessible), do: accessible
  defp dedup_itineraries({:ok, unknown}, {:ok, accessible}) do
    merged = Site.TripPlan.Merge.merge_itineraries(
      accessible,
      unknown)
    {:ok, merged}
  end

  defp include_options(%__MODULE__{} = query, opts) do
    time = cond do
      dt = opts[:arrive_by] ->
        {:arrive_by, dt}
      dt = opts[:depart_at] ->
        {:depart_at, dt}
      true ->
        {:depart_at, Util.now()}
    end
    %{query |
      time: time,
      wheelchair_accessible?: opts[:wheelchair_accessible?] == true
    }
  end

  @spec opts_from_query(map, Keyword.t) :: Keyword.t
  def opts_from_query(query, opts \\ [])
  def opts_from_query(%{"time" => "depart", "date_time" => _date_time} = query, opts) do
    do_date_time(:depart_at, query, opts)
  end
  def opts_from_query(%{"time" => "arrive", "date_time" => _date_time} = query, opts) do
    do_date_time(:arrive_by, query, opts)
  end
  def opts_from_query(%{"optimize_for" => val} = query, opts) do
    opts_from_query(
      Map.delete(query, "optimize_for"),
      optimize_for(val, opts)
    )
  end
  def opts_from_query(%{"modes" => modes} = query, opts) do
    opts_from_query(
      Map.delete(query, "modes"),
      get_mode_opts(modes, opts)
    )
  end
  def opts_from_query(_, opts) do
    opts
  end

  defp do_date_time(param, %{"date_time" => date_time} = query, opts) do
    opts_from_query(
      Map.drop(query, ["time", "date_time"]),
      Keyword.put(opts, param, date_time))
  end

  @spec get_mode_opts(map, Keyword.t) :: Keyword.t
  def get_mode_opts(%{} = modes, opts) do
    active_modes = Enum.reduce(modes, [], &get_active_modes/2)
    Keyword.put(opts, :mode, active_modes)
  end

  @spec get_active_modes({String.t, String.t}, Keyword.t) :: Keyword.t
  defp get_active_modes({"subway", "true"}, acc) do
    ["TRAM", "SUBWAY" | acc]
  end
  defp get_active_modes({"commuter_rail", "true"}, acc) do
    ["RAIL" | acc]
  end
  defp get_active_modes({"bus", "true"}, acc) do
    ["BUS" | acc]
  end
  defp get_active_modes({"ferry", "true"}, acc) do
    ["FERRY" | acc]
  end
  defp get_active_modes({_, "false"}, acc) do
    acc
  end

  @spec optimize_for(String.t, Keyword.t) :: Keyword.t
  defp optimize_for("best_route", opts) do
    opts
  end
  defp optimize_for("accessibility", opts) do
    Keyword.put(opts, :wheelchair_accessible?, true)
  end
  defp optimize_for("fewest_transfers", opts) do
    Keyword.put(opts, :optimize_for, :fewest_transfers)
  end
  defp optimize_for("less_walking", opts) do
    Keyword.put(opts, :optimize_for, :less_walking)
  end

  @doc "Determines if the given query contains any itineraries"
  @spec itineraries?(t | nil) :: boolean
  def itineraries?(%__MODULE__{itineraries: {:ok, itineraries}}) do
    !Enum.empty?(itineraries)
  end
  def itineraries?(_query), do: false

  @spec get_itineraries(t) :: [Itinerary.t]
  def get_itineraries(%__MODULE__{itineraries: {:ok, itineraries}}) do
    itineraries
  end
  def get_itineraries(%__MODULE__{itineraries: {:error, _}}) do
    []
  end
  def get_itineraries(%__MODULE__{itineraries: nil}) do
    []
  end

  @doc "Returns the name of the location for a given query"
  @spec location_name(t, :from | :to) :: String.t
  def location_name(%__MODULE__{} = query, key) when key in [:from, :to] do
    case Map.get(query, key) do
      %NamedPosition{name: name} -> name
      _ -> nil
    end
  end
end
