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
  * times: a list of %Schedules.Schedule{} for stops between either
    1) the origin and destination or 2) the break and destination
  * times_before: a list of %Schedules.Schedule{} before the "show all stops" break
  * duration: the number of minutes the trip takes between origin_id and destination_id
  """
  @type time :: Schedules.Schedule.t
  @type time_list :: [time]
  @type t :: %__MODULE__{
    route: Routes.Route.t,
    origin_id: String.t,
    destination_id: String.t,
    vehicle: Vehicles.Vehicle.t | nil,
    status: String.t,
    times: time_list,
    times_before: time_list,
    duration: pos_integer
  }

  defstruct [
    route: nil,
    origin_id: nil,
    destination_id: nil,
    vehicle: nil,
    status: "operating at normal schedule",
    times: [],
    times_before: [],
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

  @spec from_list(time_list, Keyword.t) :: TripInfo.t | {:error, any}
  def from_list(times, opts \\ []) do
    origin_id = time_stop_id(opts[:origin_id], times, :first)
    destination_id = time_stop_id(opts[:destination_id], times, :last)
    origin_ids = if opts[:vehicle] do
      [origin_id, opts[:vehicle].stop_id]
    else
      [origin_id]
    end
    times
    |> clamp_times_to_origin_destination(origin_ids, destination_id)
    |> do_from_list(origin_id, destination_id, opts)
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
    apply(List, list_function, [times]).stop.id
  end

  defp do_from_list([time, _ | _] = times, origin_id, destination_id, opts)
  when is_binary(origin_id) and is_binary(destination_id) do
    route = time.route
    duration = duration(times, origin_id)
    {before, times} = split_around_break(times, opts[:collapse?])
    %TripInfo{
      route: route,
      origin_id: origin_id,
      destination_id: destination_id,
      vehicle: opts[:vehicle],
      times_before: before,
      times: times,
      duration: duration
    }
  end
  defp do_from_list(_times, _origin_id, _destination_id, _opts) do
    {:error, "not enough times to build a trip"}
  end

  @spec full_status(TripInfo.t) :: iolist
  def full_status(%TripInfo{route: route,
                            times: times,
                            status: status}) do
    [
      route_name(route),
      " to ",
      destination(times),
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
  def times_with_flags_and_separators(%TripInfo{times_before: []} = info) do
    [times_with_flags(info)]
  end
  def times_with_flags_and_separators(%TripInfo{} = info) do
    [
      times_with_flags(info, :before),
      :separator,
      times_with_flags(info)
    ]
  end

  @doc """
  Returns the times for this trip, tagging the first/last stops.
  """
  @spec times_with_flags(TripInfo.t, atom) :: [{time, Flags.t}]
  def times_with_flags(%TripInfo{} = info, field \\ nil) do
    times = case field do
              nil ->
                info.times
              :before ->
                info.times_before
            end
    Enum.map(times, &do_time_with_flag(&1, info))
  end

  defp do_time_with_flag(time, info) do
    {time, %Flags{
        terminus?: time.stop.id in [info.origin_id, info.destination_id],
        vehicle?: info.vehicle != nil and info.vehicle.stop_id == time.stop.id
     }
    }
  end

  # Filters the list of times to those between origins and destination,
  # inclusive.  If the origin is after the trip, or one/both are not
  # included, the behavior is undefined.
  @spec clamp_times_to_origin_destination(time_list, [String.t], String.t) :: time_list
  defp clamp_times_to_origin_destination(times, origin_ids, destination_id) do
    times
    |> Enum.drop_while(& not(&1.stop.id in origin_ids))
    |> clamp_to_destination(destination_id, [])
  end

  defp clamp_to_destination([], _destination_id, _acc) do
    # if we get to the end of the list without finding the destination, don't
    # return anything.
    []
  end
  defp clamp_to_destination([%Schedules.Schedule{stop: %{id: destination_id}} = time | _], destination_id, acc) do
    [time | acc]
    |> Enum.reverse
  end
  defp clamp_to_destination([time | rest], destination_id, acc) do
    clamp_to_destination(rest, destination_id, [time | acc])
  end

  @spec split_around_break(time_list, boolean) :: {time_list, time_list}
  defp split_around_break(times, collapse?)
  defp split_around_break([_, _, _, _, _ | _] = times, true) do
    # the match makes sure we have at least 5 items to split on
    first_two = Enum.take(times, 2)
    last_two = Enum.take(times, -2)
    {first_two, last_two}
  end
  defp split_around_break(times, _) do
    {[], times}
  end

  defp duration(times, origin_id) do
    first = Enum.find(times, & &1.stop.id == origin_id)
    last = List.last(times)
    Timex.diff(last.time, first.time, :minutes)
  end

  defp route_name(%Routes.Route{type: 2, name: name}) do
    ["Bus Route ", name]
  end
  defp route_name(%Routes.Route{name: name}) do
    name
  end

  defp destination([_ | _] = times) do
    List.last(times).stop.name
  end
end
