defmodule Site.TransitNearMe do
  @moduledoc """
  Struct and helper functions for gathering data to use on TransitNearMe.
  """

  alias GoogleMaps.Geocode.Address
  alias PredictedSchedule.Display
  alias Predictions.Prediction
  alias Routes.Route
  alias Schedules.{Schedule, Trip}
  alias SiteWeb.ViewHelpers
  alias Stops.{Nearby, Stop}
  alias Util.Distance

  defstruct location: nil,
            stops: [],
            distances: %{},
            schedules: %{}

  @type schedule_data :: %{
          Route.id_t() => %{
            Trip.headsign() => Schedule.t()
          }
        }

  @type distance_hash :: %{Stop.id_t() => float}

  @type t :: %__MODULE__{
          location: Address.t() | nil,
          stops: [Stop.t()],
          distances: distance_hash,
          schedules: %{Stop.id_t() => schedule_data}
        }

  @type error :: {:error, :timeout | :no_stops}

  @default_opts [
    stops_nearby_fn: &Nearby.nearby/1,
    schedules_fn: &Schedules.Repo.schedule_for_stop/2,
    predictions_fn: &Predictions.Repo.all/1
  ]

  @spec build(Address.t(), Keyword.t()) :: t() | error
  def build(%Address{} = location, opts) do
    opts = Keyword.merge(@default_opts, opts)
    nearby_fn = Keyword.fetch!(opts, :stops_nearby_fn)

    with {:stops, [%Stop{} | _] = stops} <- {:stops, nearby_fn.(location)},
         {:schedules, {:ok, schedules}} <- {:schedules, get_schedules(stops, opts)} do
      %__MODULE__{
        location: location,
        stops: stops,
        schedules: schedules,
        distances: Map.new(stops, &{&1.id, Distance.haversine(&1, location)})
      }
    end
  end

  @spec get_schedules([Stop.t()], Keyword.t()) ::
          {:ok, %{Stop.id_t() => [Schedule.t()]}} | {:error, :timeout}
  defp get_schedules(stops, opts) do
    schedules_fn = Keyword.fetch!(opts, :schedules_fn)

    min_time =
      opts
      |> Keyword.fetch!(:now)
      |> Timex.format!("{h24}:{m}")

    stops
    |> Task.async_stream(
      fn stop -> {stop.id, schedules_fn.(stop.id, min_time: min_time)} end,
      on_timeout: :kill_task
    )
    |> Enum.reduce_while({:ok, %{}}, &collect_data/2)
  end

  @spec collect_data({:ok, any} | {:exit, :timeout}, {:ok, map | [any]}) ::
          {:cont, {:ok, map | [any]}} | {:halt, {:error, :timeout}}
  defp collect_data({:ok, {key, value}}, {:ok, %{} = acc}) do
    {:cont, {:ok, Map.put(acc, key, value)}}
  end

  defp collect_data({:ok, value}, {:ok, acc}) when is_list(acc) do
    {:cont, {:ok, [value | acc]}}
  end

  defp collect_data({:exit, :timeout}, _) do
    {:halt, {:error, :timeout}}
  end

  @spec sort_data({:ok, [any]} | {:error, :timeout}) :: [any]
  defp sort_data({:error, :timeout}) do
    []
  end

  defp sort_data({:ok, list}) when is_list(list) do
    Enum.reverse(list)
  end

  @doc """
  Builds a list of routes that stop at a Stop.
  """
  @spec routes_for_stop(t(), Stop.id_t()) :: [Route.t()]
  def routes_for_stop(%__MODULE__{schedules: schedules}, stop_id) do
    schedules
    |> Map.fetch!(stop_id)
    |> Enum.reduce(MapSet.new(), &MapSet.put(&2, &1.route))
    |> MapSet.to_list()
  end

  @doc """
  Returns the distance of a stop from the input location.
  """
  @spec distance_for_stop(t(), Stop.id_t()) :: float
  def distance_for_stop(%__MODULE__{distances: distances}, stop_id) do
    Map.fetch!(distances, stop_id)
  end

  @type simple_prediction :: %{
          required(:time) => [String.t()],
          required(:status) => String.t() | nil,
          required(:track) => String.t() | nil
        }

  @type time_data :: %{
          required(:schedule) => [String.t()],
          required(:prediction) => simple_prediction | nil
        }

  @type headsign_data :: %{
          required(:name) => String.t(),
          required(:times) => [time_data]
        }

  @type direction_data :: %{
          required(:direction_id) => 0 | 1,
          required(:headsigns) => [headsign_data]
        }

  @type stop_data :: %{
          # stop_data includes the full %Stop{} struct, plus:
          required(:directions) => [direction_data],
          required(:distance) => String.t()
        }

  @type route_data :: %{
          # route_data includes the full %Route{} struct, plus:
          required(:stops) => [stop_data]
        }

  @doc """
  Uses the schedules to build a list of route objects, which each have
  a list of stops. Each stop has a list of directions. Each direction has a
  list of headsigns. Each headsign has a schedule, and a prediction if available.
  """
  @spec schedules_for_routes(t()) :: [route_data]
  def schedules_for_routes(%__MODULE__{
        schedules: schedules,
        location: location,
        distances: distances
      }) do
    schedules
    |> Map.values()
    |> List.flatten()
    |> Enum.group_by(& &1.route.id)
    |> Enum.map(&schedules_for_route(&1, location, distances))
    |> Enum.sort_by(&route_sorter(&1, distances))
  end

  defp route_sorter(%{stops: [%{id: stop_id} | _]}, distances) do
    Map.fetch!(distances, stop_id)
  end

  @spec schedules_for_route({Route.id_t(), [Schedule.t()]}, Address.t(), distance_hash) ::
          route_data
  defp schedules_for_route({_route_id, schedules}, location, distances) do
    [%Schedule{route: route} | _] = schedules

    route
    |> Map.from_struct()
    |> Map.update!(:direction_names, fn map ->
      Map.new(map, fn {key, val} -> {Integer.to_string(key), val} end)
    end)
    |> Map.update!(:direction_destinations, fn map ->
      Map.new(map, fn {key, val} -> {Integer.to_string(key), val} end)
    end)
    |> Map.put(:stops, get_stops_for_route(schedules, location, distances, route))
  end

  @spec get_stops_for_route([Schedule.t()], Address.t(), distance_hash, Route.t()) :: [stop_data]
  defp get_stops_for_route(schedules, location, distances, route) do
    schedules
    |> Enum.group_by(& &1.stop.id)
    |> Task.async_stream(&get_directions_for_stop(&1, location), on_timeout: :kill_task)
    |> Enum.reduce_while({:ok, []}, &collect_data/2)
    |> sort_data()
    |> Enum.sort_by(&Map.fetch!(distances, &1.id))
    |> Enum.take(stop_count(route))
  end

  # show the closest two stops for bus, in order to
  # display both inbound and outbound stops
  @spec stop_count(Route.t()) :: integer
  defp stop_count(%Route{type: 3}), do: 2
  defp stop_count(_), do: 1

  @spec get_directions_for_stop({Stop.id_t(), [Schedule.t()]}, Address.t()) :: stop_data
  defp get_directions_for_stop({_stop_id, schedules}, location) do
    [%Schedule{stop: stop} | _] = schedules

    distance = Distance.haversine(stop, location)

    stop
    |> Map.from_struct()
    |> Map.put(:directions, get_direction_map(schedules))
    |> Map.put(:distance, ViewHelpers.round_distance(distance))
  end

  @spec get_direction_map([Schedule.t()]) :: [direction_data]
  defp get_direction_map(schedules) do
    schedules
    |> Enum.group_by(& &1.trip.direction_id)
    |> Task.async_stream(&build_direction_map/1, on_timeout: :kill_task)
    |> Enum.reduce_while({:ok, []}, &collect_data/2)
    |> sort_data()
  end

  @spec build_direction_map({0 | 1, [Schedule.t()]}) :: direction_data
  defp build_direction_map({direction_id, schedules}) do
    headsigns =
      schedules
      |> Enum.group_by(& &1.trip.headsign)
      |> Enum.reject(&last_stop?/1)
      |> Task.async_stream(&build_headsign_map/1, on_timeout: :kill_task)
      |> Enum.reduce_while({:ok, []}, &collect_data/2)
      |> sort_data()

    %{
      direction_id: direction_id,
      headsigns: headsigns
    }
  end

  @spec last_stop?({String.t(), [Schedule.t()]}) :: boolean
  defp last_stop?({_headsign, [%{trip: trip, stop: %{id: stop_id}} | _]}) do
    case Routes.Repo.get_shape(trip.shape_id) do
      [%{stop_ids: stop_ids}] -> stop_id == List.last(stop_ids)
      _ -> false
    end
  end

  @spec build_headsign_map({Schedules.Trip.headsign(), [Schedule.t()]}) :: headsign_data
  defp build_headsign_map({headsign, schedules}) do
    headsign_schedules =
      schedules
      |> Enum.take(2)
      |> Enum.map(&build_time_map/1)
      |> filter_headsign_schedules()

    %{
      name: headsign,
      times: headsign_schedules
    }
  end

  @spec filter_headsign_schedules([time_data]) :: [time_data]
  defp filter_headsign_schedules([%{prediction: _} = keep, %{prediction: nil}]) do
    # only show one schedule if the second schedule has no prediction
    [keep]
  end

  defp filter_headsign_schedules(schedules) do
    schedules
  end

  @spec build_time_map(Schedule.t()) :: time_data
  defp build_time_map(schedule) do
    prediction =
      [trip: schedule.trip.id]
      |> Predictions.Repo.all()
      # occasionally, a prediction will not have a time; discard if that happens
      |> Enum.filter(& &1.time)
      |> simple_prediction()

    %{
      schedule: format_time(schedule.time),
      prediction: prediction
    }
  end

  @spec simple_prediction([Prediction.t()]) :: simple_prediction | nil
  defp simple_prediction([]) do
    nil
  end

  defp simple_prediction([prediction | _]) do
    prediction
    |> Map.update!(:time, &format_prediction_time/1)
    |> Map.take([:time, :status, :track])
  end

  @spec format_prediction_time(DateTime.t()) :: [String.t()] | String.t()
  defp format_prediction_time(%DateTime{} = time) do
    Display.do_time_difference(time, Util.now(), &format_time/1)
  end

  @spec format_time(DateTime.t()) :: [String.t()]
  defp format_time(time) do
    [time, am_pm] =
      time
      |> Timex.format!("{h12}:{m} {AM}")
      |> String.split(" ")

    [time, " ", am_pm]
  end

  @doc """
  Turns a TransitNearMe struct into json.

  Data gets passed through schedules_for_routes/1 before being encoded, which transforms the
  data into a customized list of routes.
  """
  @spec to_json(t()) :: String.t()
  def to_json(%__MODULE__{} = data) do
    data
    |> schedules_for_routes()
    |> Poison.encode!()
  end
end
