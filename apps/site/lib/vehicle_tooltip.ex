defmodule VehicleTooltip do
  @moduledoc """
  Represents a vehicle with it's associated status information, used to render tooltips on schedule and
  line representations
  """
  alias Vehicles.Vehicle
  alias Predictions.Prediction
  alias Routes.Route
  alias Schedules.Trip

  import Routes.Route, only: [vehicle_name: 1]
  import Phoenix.HTML.Tag, only: [content_tag: 2, content_tag: 3]
  import Phoenix.HTML, only: [safe_to_string: 1]
  import Site.ViewHelpers, only: [format_schedule_time: 1]

  defstruct [
    vehicle: %Vehicle{},
    prediction: %Prediction{},
    trip: %Trip{},
    route: %Route{},
    stop_name: "",
  ]

  @type t :: %__MODULE__{
    vehicle: Vehicle.t,
    prediction: Prediction.t | nil,
    trip: Trip.t | nil,
    route: Route.t,
    stop_name: String.t
  }

  @doc """
  There are multiple places where vehicle tooltips are used. This function is called from the controller to
  construct a convenient map that can be used in views / templates to determine if a tooltip is available
  and to fetch all of the required data
  """
  @spec build_map(Route.t, %{{String.t, String.t} => Vehicle.t}, [Prediction.t]):: %{}
  def build_map(route, vehicle_locations, vehicle_predictions) do
    Enum.reduce(vehicle_locations, %{}, fn(vehicle_location, output) ->
      {{trip_id, stop_id}, vehicle_status} = vehicle_location
      tooltip = %VehicleTooltip{
        vehicle: vehicle_status,
        prediction: prediction_for_stop(vehicle_predictions, trip_id),
        stop_name: stop_name(Stops.Repo.get(stop_id)),
        trip: Schedules.Repo.trip(trip_id),
        route: route
      }
      output
      |> Map.merge(%{vehicle_status.stop_id => tooltip})
      |> Map.merge(%{{trip_id, stop_id} => tooltip})
    end)
  end

  @spec stop_name(Stops.Stop.t | nil) :: String.t
  defp stop_name(nil), do: ""
  defp stop_name(stop), do: stop.name

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

  @spec prediction_for_stop([Prediction.t] | nil, String.t) :: Prediction.t
  defp prediction_for_stop(nil, _) do
    nil
  end
  defp prediction_for_stop(vehicle_predictions, trip_id) do
    Enum.find(vehicle_predictions, &match?(%{trip: %{id: ^trip_id}}, &1))
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
