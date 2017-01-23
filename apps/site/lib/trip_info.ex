defmodule TripInfo do
  @moduledoc """
  Wraps the important information about a trip.
  """
  @type time :: Schedules.Schedule.t
  @type time_list :: [time]
  @type t :: %__MODULE__{
    route: Routes.Route.t,
    origin: String.t,
    destination: String.t,
    vehicle: Vehicles.Vehicle.t | nil,
    status: String.t,
    times: time_list,
    duration: pos_integer
  }

  defstruct [
    route: nil,
    origin: nil,
    destination: nil,
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
  def from_list(times, opts \\ [])
  def from_list([_, _ | _] = times, opts) do
    origin = opts[:origin] || List.first(times).stop.id
    destination = opts[:destination] || List.last(times).stop.id
    times = clamp_times_to_origin_destination(times, origin, destination)
    case times do
      [time, _ | _] ->
        route = time.route
        duration = duration(times)
        %TripInfo{
          route: route,
          origin: origin,
          destination: destination,
          vehicle: opts[:vehicle],
          times: times,
          duration: duration
        }
      _ ->
        {:error, "not enough times to build a trip"}
    end
  end
  def from_list(_times, _opts) do
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
  Returns the times for this trip, tagging the first/last stops.
  """
  @spec times_with_flags(TripInfo.t) :: [{time, Flags.t}]
  def times_with_flags(%TripInfo{times: times} = info) do
    Enum.map(times, &do_time_with_flag(&1, info))
  end

  defp do_time_with_flag(time, info) do
    {time, %Flags{
        terminus?: time.stop.id in [info.origin, info.destination],
        vehicle?: info.vehicle != nil and info.vehicle.stop_id == time.stop.id
     }
    }
  end

  # Filters the list of times to those between origin and destination,
  # inclusive.  If the origin is after the trip, or one/both are not
  # included, the behavior is undefined.
  @spec clamp_times_to_origin_destination(time_list, String.t, String.t) :: time_list
  defp clamp_times_to_origin_destination(times, origin_id, destination_id)
  defp clamp_times_to_origin_destination(times, origin_id, destination_id) do
    times
    |> Enum.drop_while(& &1.stop.id != origin_id)
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
end
