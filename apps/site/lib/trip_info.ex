defmodule TripInfo do
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
    status: String.t,
    sections: [time_list],
    duration: pos_integer
  }

  defstruct [
    route: nil,
    origin_id: nil,
    destination_id: nil,
    vehicle: nil,
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
    times
    |> clamp_times_to_origin_destination(starting_stop_ids, destination_id)
    |> do_from_list(starting_stop_ids, destination_id, opts)
  end

  @doc """
  Checks whether a trip id matches the trip being represented by the TripInfo.
  """
  @spec is_current_trip?(TripInfo.t, String.t) :: boolean
  def is_current_trip?(nil, _), do: false
  def is_current_trip?(%TripInfo{sections: []}, _), do: false
  def is_current_trip?(%TripInfo{sections: [[%PredictedSchedule{schedule: %Schedules.Schedule{trip: trip}} | _] | _]}, trip_id) do
    trip.id == trip_id
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
    |> PredictedSchedule.stop_id()
  end

  defp do_from_list([time, _ | _] = times, [origin_id | _] = starting_stop_ids, destination_id, opts)
  when is_binary(origin_id) and is_binary(destination_id) do
    route = time.schedule.route
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
      duration: duration
    }
  end
  defp do_from_list(_times, _starting_stop_ids, _destination_id, _opts) do
    {:error, "not enough times to build a trip"}
  end

  @doc """
  Returns a long status string suitable for display to a user.
  """
  @spec full_status(TripInfo.t) :: iolist
  def full_status(%TripInfo{route: route,
                            sections: sections,
                            status: status}) do
    [
      route_name(route),
      " to ",
      destination(List.last(sections)),
      " ",
      status
    ]
  end

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
          terminus?: PredictedSchedule.stop_id(time) in [info.origin_id, info.destination_id],
          vehicle?: info.vehicle != nil and info.vehicle.stop_id == PredictedSchedule.stop_id(time)
       }
      }
    end)
  end

  # Filters the list of times to those between origins and destination,
  # inclusive.  If the origin is after the trip, or one/both are not
  # included, the behavior is undefined.
  @spec clamp_times_to_origin_destination(time_list, [String.t], String.t) :: time_list
  defp clamp_times_to_origin_destination(times, starting_stop_ids, destination_id) do
    times
    |> Enum.drop_while(& not(PredictedSchedule.stop_id(&1) in starting_stop_ids))
    |> clamp_to_destination(destination_id, [])
  end

  defp clamp_to_destination([], _destination_id, _acc) do
    # if we get to the end of the list without finding the destination, don't
    # return anything.
    []
  end
  defp clamp_to_destination([%PredictedSchedule{schedule: %Schedules.Schedule{stop: %{id: destination_id}}} = time | _], destination_id, acc) do
    [time | acc]
    |> Enum.reverse
  end
  defp clamp_to_destination([time | rest], destination_id, acc) do
    clamp_to_destination(rest, destination_id, [time | acc])
  end

  defp duration(times, origin_id) do
    first = Enum.find(times, & PredictedSchedule.stop_id(&1) == origin_id)
    last = List.last(times)
    Timex.diff(PredictedSchedule.time(last), PredictedSchedule.time(first), :minutes)
  end

  defp route_name(%Routes.Route{type: 3, name: name}) do
    ["Bus Route ", name]
  end
  defp route_name(%Routes.Route{name: name}) do
    name
  end

  defp destination([_ | _] = times) do
    List.last(times).schedule.stop.name
  end
end
