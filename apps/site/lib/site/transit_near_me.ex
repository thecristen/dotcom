defmodule Site.TransitNearMe do
  @moduledoc """
  Struct and helper functions for gathering data to use on TransitNearMe.
  """

  alias GoogleMaps.Geocode.Address
  alias PredictedSchedule.Display
  alias Predictions.Prediction
  alias Routes.Route
  alias Schedules.{Schedule, Trip}
  alias SiteWeb.Router.Helpers
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
    now = Keyword.fetch!(opts, :now)

    min_time = format_min_time(now)

    stops
    |> Task.async_stream(
      fn stop ->
        {
          stop.id,
          stop.id
          |> schedules_fn.(min_time: min_time)
          |> Enum.reject(& &1.last_stop?)
        }
      end,
      on_timeout: :kill_task
    )
    |> Enum.reduce_while({:ok, %{}}, &collect_data/2)
  end

  def format_min_time(%DateTime{hour: hour, minute: minute}) do
    format_min_hour(hour) <> ":" <> format_time_integer(minute)
  end

  defp format_min_hour(hour) when hour in [0, 1, 2] do
    # use integer > 24 to return times after midnight for the service day
    Integer.to_string(24 + hour)
  end

  defp format_min_hour(hour) do
    format_time_integer(hour)
  end

  defp format_time_integer(num) when num < 10 do
    "0" <> Integer.to_string(num)
  end

  defp format_time_integer(num) do
    Integer.to_string(num)
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
          required(:scheduled_time) => [String.t()],
          required(:prediction) => simple_prediction | nil
        }

  @type headsign_data :: %{
          required(:name) => String.t(),
          required(:times) => [time_data],
          required(:train_number) => String.t() | nil
        }

  @type direction_data :: %{
          required(:direction_id) => 0 | 1,
          required(:headsigns) => [headsign_data]
        }

  @type stop_data :: %{
          # stop_data includes the full %Stop{} struct, plus:
          required(:directions) => [direction_data],
          required(:distance) => String.t(),
          required(:href) => String.t()
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
    |> Enum.filter(&coming_today_if_bus(&1, &1.route.type))
    |> Enum.group_by(& &1.route.id)
    |> Enum.map(&schedules_for_route(&1, location, distances))
    |> Enum.sort_by(&route_sorter(&1, distances))
  end

  @spec coming_today_if_bus(Schedule.t(), 0..4) :: boolean
  defp coming_today_if_bus(schedule, 3) do
    twenty_four_hours_in_seconds = 86_400

    DateTime.diff(schedule.time, Util.now()) < twenty_four_hours_in_seconds
  end

  defp coming_today_if_bus(_schedule, _non_bus_route_type) do
    true
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
      Map.new(map, fn {key, val} -> {Integer.to_string(key), Route.add_direction_suffix(val)} end)
    end)
    |> Map.update!(:direction_destinations, fn map ->
      Map.new(map, fn {key, val} -> {Integer.to_string(key), val} end)
    end)
    |> Map.update!(:name, fn name -> ViewHelpers.break_text_at_slash(name) end)
    |> Map.put(:stops, get_stops_for_route(schedules, location, distances))
  end

  @spec get_stops_for_route([Schedule.t()], Address.t(), distance_hash) :: [stop_data]
  defp get_stops_for_route(schedules, location, distances) do
    schedules
    |> Enum.group_by(& &1.stop.id)
    |> Task.async_stream(&get_directions_for_stop(&1, location), on_timeout: :kill_task)
    |> Enum.reduce_while({:ok, []}, &collect_data/2)
    |> sort_data()
    |> Enum.sort_by(&Map.fetch!(distances, &1.id))
  end

  @spec get_directions_for_stop({Stop.id_t(), [Schedule.t()]}, Address.t()) :: stop_data
  defp get_directions_for_stop({_stop_id, schedules}, location) do
    [%Schedule{stop: schedule_stop} | _] = schedules
    stop = Stops.Repo.get(schedule_stop.id)

    distance = Distance.haversine(stop, location)
    href = Helpers.stop_path(SiteWeb.Endpoint, :show, stop.id)

    stop
    |> Map.from_struct()
    |> Map.put(:directions, get_direction_map(schedules))
    |> Map.put(:distance, ViewHelpers.round_distance(distance))
    |> Map.put(:href, href)
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
      |> Task.async_stream(&build_headsign_map/1, on_timeout: :kill_task)
      |> Enum.reduce_while({:ok, []}, &collect_data/2)
      |> sort_data()

    %{
      direction_id: direction_id,
      headsigns: headsigns
    }
  end

  @spec build_headsign_map({Schedules.Trip.headsign(), [Schedule.t()]}) :: headsign_data
  defp build_headsign_map({headsign, schedules}) do
    [%{route: route, trip: trip} | _] = schedules

    headsign_schedules =
      schedules
      |> Enum.take(schedule_count(route))
      |> Enum.map(&build_time_map/1)
      |> filter_headsign_schedules()

    %{
      name: ViewHelpers.break_text_at_slash(headsign),
      times: headsign_schedules,
      train_number: trip.name
    }
  end

  defp schedule_count(%Route{type: 2}), do: 1
  defp schedule_count(%Route{}), do: 2

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
    route_type = Route.type_atom(schedule.route)

    prediction =
      [trip: schedule.trip.id]
      |> Predictions.Repo.all()
      # occasionally, a prediction will not have a time; discard if that happens
      |> Enum.filter(& &1.time)
      |> simple_prediction(route_type)

    %{
      scheduled_time: format_time(schedule.time),
      prediction: prediction
    }
  end

  @spec simple_prediction([Prediction.t()], atom) :: simple_prediction | nil
  def simple_prediction([], _) do
    nil
  end

  def simple_prediction([prediction | _], route_type) do
    prediction
    |> Map.update!(:time, &format_prediction_time(&1, route_type))
    |> Map.take([:time, :status, :track])
  end

  @spec format_prediction_time(DateTime.t(), atom) :: [String.t()] | String.t()
  defp format_prediction_time(%DateTime{} = time, :commuter_rail) do
    format_time(time)
  end

  defp format_prediction_time(%DateTime{} = time, _) do
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
end
