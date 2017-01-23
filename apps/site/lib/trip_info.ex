defmodule TripInfo do
  @moduledoc """
  Wraps the important information about a trip.
  """
  @type time :: Schedules.Schedule.t
  @type time_list :: [time]
  @type t :: %__MODULE__{
    route: Routes.Route.t,
    vehicle: Vehicles.Vehicle.t | nil,
    status: String.t,
    times: time_list,
    duration: pos_integer
  }

  defstruct [
    route: nil,
    vehicle: nil,
    status: "operating at normal schedule",
    times: [],
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
    times = clamp_times_to_origin_destination(times, opts[:origin], opts[:destination])
    case times do
      [time, _ | _] ->
        route = time.route
        duration = duration(times)
        %TripInfo{
          route: route,
          vehicle: opts[:vehicle],
          times: times,
          duration: duration
        }
      _ ->
        {:error, "not enough times to build a trip"}
    end
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
  Returns the times for this trip, tagging the first/last stops.
  """
  @spec times_with_flags(TripInfo.t) :: [{time, Flags.t}]
  def times_with_flags(%TripInfo{times: times, vehicle: vehicle}) do
    do_times_with_flags(times, vehicle, [])
  end

  # Filters the list of times to those between origin and destination,
  # inclusive.  If the origin is after the trip, or one/both are not
  # included, the behavior is undefined.
  @spec clamp_times_to_origin_destination(time_list, String.t | nil, String.t | nil) :: time_list
  defp clamp_times_to_origin_destination(times, origin_id, destination_id)
  defp clamp_times_to_origin_destination(times, nil, nil) do
    times
  end
  defp clamp_times_to_origin_destination(times, origin_id, nil) do
    Enum.drop_while(times, & &1.stop.id != origin_id)
  end
  defp clamp_times_to_origin_destination(times, origin_id, destination_id) do
    times
    |> clamp_times_to_origin_destination(origin_id, nil)
    |> clamp_to_destination(destination_id, [])
  end

  defp clamp_to_destination([%Schedules.Schedule{stop: %{id: id}} = time | _], id, acc) do
    [time | acc]
    |> Enum.reverse
  end
  defp clamp_to_destination([time | rest], id, acc) do
    clamp_to_destination(rest, id, [time | acc])
  end

  defp duration([first | rest]) do
    last = List.last(rest)
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

  defp do_times_with_flags(times, vehicle, acc)
  defp do_times_with_flags([time], vehicle, acc) do
    flag = %Flags{
      terminus?: true,
      vehicle?: has_vehicle?(time, vehicle)
    }
    [{time, flag} | acc]
    |> Enum.reverse
  end
  defp do_times_with_flags([time | rest], vehicle, []) do
    flag = %Flags{
      terminus?: true,
      vehicle?: has_vehicle?(time, vehicle)
    }
    do_times_with_flags(rest, vehicle, [{time, flag}])
  end
  defp do_times_with_flags([time | rest], vehicle, acc) do
    flag = %Flags{
      vehicle?: has_vehicle?(time, vehicle)
    }
    do_times_with_flags(rest, vehicle, [{time, flag} | acc])
  end

  defp has_vehicle?(
    %Schedules.Schedule{stop: %{id: id}},
    %Vehicles.Vehicle{stop_id: id}) do
    true
  end
  defp has_vehicle?(%Schedules.Schedule{}, _vehicle) do
    false
  end
end
