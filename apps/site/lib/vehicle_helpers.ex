defmodule VehicleHelpers do
  @moduledoc """
  Various functions for working on lists of vehicle to show on a map, or render tooltips.
  """
  alias Vehicles.Vehicle
  alias Predictions.Prediction
  alias Routes.{Route, Shape}
  alias Schedules.Trip
  alias Site.ScheduleV2Controller.VehicleLocations

  import Routes.Route, only: [vehicle_name: 1]
  import Phoenix.HTML.Tag, only: [content_tag: 2, content_tag: 3]
  import Phoenix.HTML, only: [safe_to_string: 1]
  import Site.ViewHelpers, only: [format_schedule_time: 1]

  @doc """
  There are multiple places where vehicle tooltips are used. This function is called from the controller to
  construct a convenient map that can be used in views / templates to determine if a tooltip is available
  and to fetch all of the required data
  """
  @spec build_tooltip_index(Route.t, VehicleLocations.t, [Prediction.t]) ::
    %{optional({String.t, String.t}) => VehicleTooltip.t, optional(String.t) => VehicleTooltip.t}
  def build_tooltip_index(route, vehicle_locations, vehicle_predictions) do
    indexed_predictions = index_vehicle_predictions(vehicle_predictions)

    vehicle_locations
    |> Stream.reject(fn({{trip_id, stop_id}, _status}) -> is_nil(trip_id) or is_nil(stop_id) end)
    |> Enum.reduce(%{}, fn(vehicle_location, output) ->
      {{trip_id, stop_id}, vehicle_status} = vehicle_location
      tooltip = %VehicleTooltip{
        vehicle: vehicle_status,
        prediction: prediction_for_stop(indexed_predictions, trip_id, stop_id),
        stop_name: stop_name(Stops.Repo.get(stop_id)),
        trip: Schedules.Repo.trip(trip_id),
        route: route
      }
      output
      |> Map.merge(%{vehicle_status.stop_id => tooltip})
      |> Map.merge(%{{trip_id, stop_id} => tooltip})
    end)
  end

  @spec prediction_for_stop(VehicleLocations.t, String.t, String.t) :: Prediction.t | nil
  defp prediction_for_stop(vehicle_predictions, trip_id, stop_id) do
    Map.get(vehicle_predictions, {trip_id, stop_id})
  end

  @spec index_vehicle_predictions([Prediction.t]) :: %{{String.t, String.t} => Prediction.t}
  defp index_vehicle_predictions(predictions) do
    predictions
    |> Stream.filter(&(&1.trip && &1.stop))
    |> Stream.map(&({{&1.trip.id, &1.stop.id}, &1}))
    |> Enum.into(Map.new)
  end

  @spec stop_name(Stops.Stop.t | nil) :: String.t
  defp stop_name(nil), do: ""
  defp stop_name(stop), do: stop.name

  @doc """
  Get polylines for vehicles that didn't already have their shape included when the route polylines were requested
  """
  @spec get_vehicle_polylines(VehicleLocations.t, [Shape.t]) :: [String.t]
  def get_vehicle_polylines(locations, route_shapes) do
    vehicle_shape_ids = vehicle_shape_ids(locations)
    route_shape_ids = MapSet.new(route_shapes, & &1.id)

    vehicle_shape_ids
    |> MapSet.difference(route_shape_ids)
    |> Enum.filter_map(&is_binary(&1), &Routes.Repo.get_shape(&1))
    |> Enum.filter_map(&(!Enum.empty?(&1)), fn([%Shape{} = shape | _]) ->
      shape.polyline
    end)
  end

  @spec vehicle_shape_ids(VehicleLocations.t) :: MapSet.t
  defp vehicle_shape_ids(locations) do
    locations
    |> Map.values()
    |> Enum.filter_map(&is_binary(&1.shape_id), & &1.shape_id)
    |> MapSet.new()
  end

  @doc """
  Function used to return tooltip text for a VehicleTooltip struct
  """
  @spec tooltip(VehicleTooltip.t | nil) :: Phoenix.HTML.Safe.t
  def tooltip(nil) do
    ""
  end
  def tooltip(%{prediction: prediction, vehicle: vehicle, trip: trip, stop_name: stop_name, route: route}) do
    time_text = prediction_time_text(prediction)
    status_text = prediction_status_text(prediction)
    stop_text = prediction_stop_text(trip, stop_name, vehicle, route)
    build_prediction_tooltip(time_text, status_text, stop_text)
  end

  @spec prediction_status_text(Prediction.t | nil) :: iodata
  defp prediction_status_text(%Prediction{status: status, track: track}) when not is_nil(track) do
    [String.capitalize(status), " on track ", track]
  end
  defp prediction_status_text(_) do
    []
  end

  @spec prediction_time_text(Prediction.t | nil) :: iodata
  defp prediction_time_text(nil) do
    []
  end
  defp prediction_time_text(%Prediction{time: nil}) do
    []
  end
  defp prediction_time_text(%Prediction{time: time, departing?: true}) do
    ["Expected departure at ", format_schedule_time(time)]
  end
  defp prediction_time_text(%Prediction{time: time}) do
    ["Expected arrival at ", format_schedule_time(time)]
  end

  @spec prediction_stop_text(Trip.t | nil, String.t, Vehicle.t | nil, Route.t) :: iodata
  defp prediction_stop_text(trip, stop_name, %Vehicle{status: status}, route) do
    [display_headsign_text(trip),
     String.downcase(vehicle_name(route)),
     display_trip_name(route, trip),
     prediction_stop_status_text(status),
     stop_name]
  end

  @spec display_headsign_text(Trip.t | nil) :: String.t
  defp display_headsign_text(%{headsign: headsign}), do: "#{headsign} "
  defp display_headsign_text(_), do: ""

  @spec prediction_stop_status_text(atom) :: String.t
  defp prediction_stop_status_text(:incoming), do: " is on the way to "
  defp prediction_stop_status_text(:stopped), do: " has arrived at "
  defp prediction_stop_status_text(:in_transit), do: " has left "

  @spec display_trip_name(Route.t, Trip.t) :: String.t
  defp display_trip_name(%{type: 2}, trip), do: " #{trip.name}"
  defp display_trip_name(_, _), do: ""

  @spec build_prediction_tooltip(iodata, iodata, iodata) :: String.t
  defp build_prediction_tooltip(time_text, status_text, stop_text) do
    time_tag = do_build_prediction_tooltip(time_text)
    status_tag = do_build_prediction_tooltip(status_text)
    stop_tag = do_build_prediction_tooltip(stop_text)

    :div
    |> content_tag([stop_tag, time_tag, status_tag])
    |> safe_to_string
    |> String.replace(~s("), ~s('))
  end

  @spec do_build_prediction_tooltip(iodata) :: Phoenix.HTML.Safe.t
  defp do_build_prediction_tooltip([]) do
    ""
  end
  defp do_build_prediction_tooltip(text) do
    content_tag(:p, text, class: 'prediction-tooltip')
  end
end
