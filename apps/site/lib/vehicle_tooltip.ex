defmodule VehicleTooltip do
  @moduledoc """
  Represents a vehicle with it's associated status information, used to render tooltips on schedule and
  line representations
  """
  alias Vehicles.Vehicle
  alias Predictions.Prediction

  import Site.ViewHelpers, only: [route_type_name: 1]
  import Phoenix.HTML.Tag, only: [content_tag: 2, content_tag: 3]
  import Phoenix.HTML, only: [safe_to_string: 1]

  defstruct [
    vehicle: %Vehicle{},
    prediction: %Prediction{},
    stop_name: "",
    trip_name: "",
    route_type: 0
  ]

  @type t :: %__MODULE__{
    vehicle: Vehicle.t,
    prediction: Prediction.t,
    stop_name: String.t,
    trip_name: String.t,
    route_type: 0..4
  }

  @doc """
  There are multiple places where vehicle tooltips are used. This function is called from the controller to
  construct a convenient map that can be used in views / templates to determine if a tooltip is available
  and to fetch all of the required data
  """
  @spec build_map(0..4, %{{String.t, String.t} => Vehicle.t}, [Prediction.t]):: %{}
  def build_map(route_type, vehicle_locations, vehicle_predictions) do
    Enum.reduce(vehicle_locations, %{}, fn(vehicle_location, output) ->
      {{trip_id, stop_id}, vehicle_status} = vehicle_location
      tooltip = %VehicleTooltip{
        vehicle: vehicle_status,
        prediction: prediction_for_stop(vehicle_predictions, vehicle_status.trip_id),
        stop_name: stop_name(Stops.Repo.get(stop_id)),
        trip_name: trip_name(Schedules.Repo.trip(trip_id)),
        route_type: route_type
      }
      output
      |> Map.merge(%{vehicle_status.stop_id => tooltip})
      |> Map.merge(%{{trip_id, stop_id} => tooltip})
    end)
  end

  @spec stop_name(Stops.Stop.t | nil) :: String.t
  defp stop_name(nil), do: ""
  defp stop_name(stop), do: stop.name

  @spec trip_name(Schedules.Trip.t | nil) :: String.t
  defp trip_name(nil), do: ""
  defp trip_name(trip), do: trip.name

  @doc """
  Function used to return tooltip text for a VehicleTooltip struct
  """
  @spec tooltip(VehicleTooltip.t | nil) :: Phoenix.HTML.Safe.t
  def tooltip(nil) do
    ""
  end
  def tooltip(%{prediction: prediction, vehicle: vehicle, stop_name: stop_name, route_type: route_type, trip_name: trip_name}) do
    time_text = prediction_time_text(prediction)
    status_text = prediction_status_text(prediction)
    stop_text = prediction_stop_text(stop_name, vehicle, route_type, trip_name)
    build_prediction_tooltip(time_text, status_text, stop_text)
  end

  @spec prediction_for_stop([Prediction.t] | nil, String.t) :: Prediction.t
  defp prediction_for_stop(nil, _) do
    nil
  end
  defp prediction_for_stop(vehicle_predictions, trip_id) do
    Enum.find(vehicle_predictions, &match?(%{trip: %{id: ^trip_id}}, &1))
  end

  @spec prediction_status_text(Predictions.Prediction.t | nil) :: iodata
  defp prediction_status_text(%Predictions.Prediction{status: status, track: track}) when not is_nil(track) do
    [String.capitalize(status), " on track ", track]
  end
  defp prediction_status_text(_) do
    ""
  end

  @spec prediction_time_text(Predictions.Prediction.t | nil) :: iodata
  defp prediction_time_text(nil) do
    ""
  end
  defp prediction_time_text(%Predictions.Prediction{time: nil}) do
    ""
  end
  defp prediction_time_text(%Predictions.Prediction{time: time, departing?: true}) do
    do_prediction_time_text("Departure", time)
  end
  defp prediction_time_text(%Predictions.Prediction{time: time}) do
    do_prediction_time_text("Arrival", time)
  end

  defp do_prediction_time_text(prefix, time) do
    [prefix, ": ", Timex.format!(time, "{h12}:{m} {AM}")]
  end

  @spec prediction_stop_text(String.t, Vehicles.Vehicle.t | nil, 0..4, String.t) :: String.t
  defp prediction_stop_text(name, %Vehicles.Vehicle{status: :incoming}, route_type, trip_name), do: "#{route_type_name(route_type)}#{display_trip_name(route_type, trip_name)} is on the way to #{name}"
  defp prediction_stop_text(name, %Vehicles.Vehicle{status: :stopped}, route_type, trip_name), do: "#{route_type_name(route_type)}#{display_trip_name(route_type, trip_name)} has arrived at #{name}"
  defp prediction_stop_text(name, %Vehicles.Vehicle{status: :in_transit}, route_type, trip_name), do: "#{route_type_name(route_type)}#{display_trip_name(route_type, trip_name)} has left #{name}"

  @spec display_trip_name(0..4, String.t) :: String.t
  defp display_trip_name(2, trip_name), do: " #{trip_name}"
  defp display_trip_name(_, _), do: ""

  @spec build_prediction_tooltip(String.t, String.t, String.t) :: String.t
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
  defp do_build_prediction_tooltip("") do
    ""
  end
  defp do_build_prediction_tooltip(text) do
    content_tag(:p, text, class: 'prediction-tooltip')
  end
end
