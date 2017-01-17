defmodule Site.ScheduleV2.TripInfoView do
  alias Routes.Route
  alias Schedules.Schedule

  @type t :: {{String.t, String.t}, String.t}

  @doc """
  Turns route into a human-readable string:
    - "Bus Route" <> route.name for bus routes
    - route.name for all other route types
  """
  @spec full_route_name(Route.t) :: String.t
  def full_route_name(%Route{type: 3, name: name}), do: "Bus Route " <> name
  def full_route_name(%Route{name: name}), do: name


  @doc """
  Calculates the difference in minutes between the start and end of the trip.
  """
  @spec scheduled_duration([Schedule.t]) :: String.t
  def scheduled_duration(trip_schedules) do
    do_scheduled_duration List.first(trip_schedules), List.last(trip_schedules)
  end

  @spec do_scheduled_duration(Schedule.t, Schedule.t) :: String.t
  defp do_scheduled_duration(%Schedule{time: origin}, %Schedule{time: destination}) do
    destination
    |> Timex.diff(origin, :minutes)
    |> Integer.to_string
  end
  defp do_scheduled_duration(nil, nil), do: ""
end
