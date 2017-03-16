defmodule TripInfo do
  require Routes.Route
  alias Routes.Route
  @moduledoc """
  Wraps the important information about a trip.

  * route: the %Routes.Route{} the trip is on
  * origin_id: the ID of the stop where we consider the trip to start.
    This is either the real start, or the origin the user selected.
  * destination_id: the ID of the stop where we consider the trip to end.
    This is either the real end, or the destination that the user selected.
  * vehicle: a %Vehicles.Vehicle{} that's on this trip, or nil
  * status: a text status of the trip relative to the schedule
  * sections: a list of lists of PredictedSchedule's, for stops between either
    1) the origin and destination or 2) the vehicle and destination
    These are broken into groups to hide some stops.
  * duration: the number of minutes the trip takes between origin_id and destination_id
  """
  @type time :: PredictedSchedule.t
  @type time_list :: [time]
  @type t :: %__MODULE__{
    route: Routes.Route.t,
    origin_id: String.t,
    destination_id: String.t,
    vehicle: Vehicles.Vehicle.t | nil,
    vehicle_stop_name: String.t | nil,
    status: String.t,
    sections: [time_list],
    duration: pos_integer
  }

  defstruct [
    route: nil,
    origin_id: nil,
    destination_id: nil,
    vehicle: nil,
    vehicle_stop_name: nil,
    status: "operating at normal schedule",
    sections: [],
    duration: -1,
  ]

  defmodule Flags do
    @type t :: %__MODULE__{
      terminus?: boolean,
      vehicle?: boolean
    }

    defstruct [
      terminus?: false,
      vehicle?: false
    ]
  end
  alias __MODULE__.Flags

  @doc """
  Given a list of times and options, creates a new TripInfo struct or returns an error.
  """
  @spec from_list(time_list, Keyword.t) :: TripInfo.t | {:error, any}
  def from_list(times, opts \\ []) do
    origin_id = time_stop_id(opts[:origin_id], times, :first)
    destination_id = time_stop_id(opts[:destination_id], times, :last)
    starting_stop_ids = if opts[:vehicle] do
      [origin_id, opts[:vehicle].stop_id]
    else
      [origin_id]
    end
    vehicle_stop_name = vehicle_stop_name(opts[:vehicle], times)
    times
    |> clamp_times_to_origin_destination(origin_id, destination_id)
    |> do_from_list(starting_stop_ids, destination_id, vehicle_stop_name, opts)
  end

  @spec vehicle_stop_name(Vehicles.Vehicle.t | nil, time_list) :: String.t | nil
  defp vehicle_stop_name(vehicle, times)
  defp vehicle_stop_name(nil, _times) do
    nil
  end
  defp vehicle_stop_name(vehicle, times) do
    case Enum.find(times, &PredictedSchedule.stop(&1).id == vehicle.stop_id) do
      nil -> nil
      schedule -> PredictedSchedule.stop(schedule).name
    end
  end

  @doc """
  Checks whether a trip id matches the trip being represented by the TripInfo.
  """
  @spec is_current_trip?(TripInfo.t, String.t) :: boolean
  def is_current_trip?(nil, _), do: false
  def is_current_trip?(%TripInfo{sections: []}, _), do: false
  def is_current_trip?(%TripInfo{sections: [[predicted_schedule | _] | _]}, trip_id) do
    case PredictedSchedule.trip(predicted_schedule) do
      %{id: ^trip_id} -> true
      _ -> false
    end
  end

  # finds a stop ID.  If one isn't provided, or is provided as nil, then
  # use a List function to get the stop ID from the times list.
  @spec time_stop_id(String.t, time_list, :first | :last) :: String.t | nil
  defp time_stop_id(stop_id_from_opts, times, list_function)
  defp time_stop_id(stop_id, _, _) when is_binary(stop_id) do
    stop_id
  end
  defp time_stop_id(_, [], _) do
    nil
  end
  defp time_stop_id(_, times, list_function) do
    List
    |> apply(list_function, [times])
    |> PredictedSchedule.stop()
    |> (fn stop -> stop.id end).()
  end

  defp do_from_list([time, _ | _] = times, [origin_id | _] = starting_stop_ids, destination_id, vehicle_stop_name, opts)
  when is_binary(origin_id) and is_binary(destination_id) do
    route = PredictedSchedule.route(time)
    duration = duration(times, origin_id)
    sections = if opts[:collapse?] do
      TripInfo.Split.split(times, starting_stop_ids)
    else
      [times]
    end

    %TripInfo{
      route: route,
      origin_id: origin_id,
      destination_id: destination_id,
      vehicle: opts[:vehicle],
      sections: sections,
      duration: duration,
      vehicle_stop_name: vehicle_stop_name
    }
  end
  defp do_from_list(_times, _starting_stop_ids, _destination_id, _vehicle_stop_name, _opts) do
    {:error, "not enough times to build a trip"}
  end

  @doc """
  Returns a long status string suitable for display to a user.
  """
  @spec full_status(TripInfo.t) :: iodata | nil
  def full_status(%TripInfo{vehicle: %{status: status}, vehicle_stop_name: vehicle_stop_name, route: route})
  when vehicle_stop_name != nil do
    vehicle = Routes.Route.vehicle_name(route)
    case status do
      :incoming ->
        [vehicle, " is on the way to ", vehicle_stop_name, "."]
      :stopped ->
        [vehicle, " has arrived at ", vehicle_stop_name, "."]
      :in_transit ->
        [vehicle, " has left ", vehicle_stop_name, "."]
    end
  end
  def full_status(_), do: nil

  @doc """
  Returns a list of either :separator or [{time, Flags.t}].  If we've
  collapsed the times for any reason, :separator will be returned to
  represent stops that are not being returned.
  """
  @spec times_with_flags_and_separators(TripInfo.t) :: [:separator | [{time, Flags.t}]]
  def times_with_flags_and_separators(%TripInfo{sections: sections} = info) do
    sections
    |> Enum.map(&do_times_with_flag(&1, info))
    |> Enum.intersperse(:separator)
  end

  defp do_times_with_flag(times, info) do
    times
    |> Enum.map(fn time ->
      {time, %Flags{
          terminus?: PredictedSchedule.stop(time).id in [info.origin_id, info.destination_id],
          vehicle?: info.vehicle != nil and info.vehicle.stop_id == PredictedSchedule.stop(time).id
       }
      }
    end)
  end

  @doc "Determines if given TripInfo contains any predictions"
  @spec any_predictions?(TripInfo.t) :: boolean
  def any_predictions?(%TripInfo{sections: sections}) do
    sections
    |> List.flatten
    |> Enum.any?(&PredictedSchedule.has_prediction?/1)
  end

  # Filters the list of times to those between origin and destination,
  # inclusive.  If the origin is after the trip, or one/both are not
  # included, the behavior is undefined.
  @spec clamp_times_to_origin_destination(time_list, String.t, String.t) :: time_list
  defp clamp_times_to_origin_destination(times, origin_id, destination_id) do
    times
    |> Enum.drop_while(& origin_id != PredictedSchedule.stop(&1).id)
    |> clamp_to_destination(destination_id, [])
  end

  defp clamp_to_destination([], _destination_id, _acc) do
    # if we get to the end of the list without finding the destination, don't
    # return anything.
    []
  end
  defp clamp_to_destination([time | rest], destination_id, acc) do
    if PredictedSchedule.stop(time).id == destination_id do
      [time | acc]
      |> Enum.reverse
    else
      clamp_to_destination(rest, destination_id, [time | acc])
    end
  end

  defp duration(times, origin_id) do
    first = Enum.find(times, & PredictedSchedule.stop(&1).id == origin_id)
    last = List.last(times)
    Timex.diff(PredictedSchedule.time(last), PredictedSchedule.time(first), :minutes)
  end

  @doc "Determines if the trip info box should be displayed"
  @spec should_display_trip_info?(TripInfo.t | nil) :: boolean
  def should_display_trip_info?(nil), do: false
  def should_display_trip_info?(trip_info) do
    not Route.subway?(trip_info.route.type) or TripInfo.any_predictions?(trip_info)
  end
end
