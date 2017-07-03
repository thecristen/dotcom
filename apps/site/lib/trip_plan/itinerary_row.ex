defmodule Site.TripPlan.ItineraryRow do
  alias Site.TripPlan.Step
  alias TripPlan.{PersonalDetail, TransitDetail, NamedPosition, Leg}
  alias TripPlan.PersonalDetail.Step

  @typep name_and_id :: {String.t | nil, String.t | nil}

  defstruct [
    stop: {nil, nil},
    route: nil,
    trip: nil,
    arrival: nil,
    departure: nil,
    transit?: false,
    steps: []
  ]

  @type t :: %__MODULE__{
    stop: name_and_id,
    transit?: boolean,
    route: Routes.Route.t | nil,
    trip: Schedules.Trip.t | nil,
    arrival: DateTime.t,
    departure: DateTime.t,
    steps: [Step.t]
  }

  def from_leg(leg) do
    %__MODULE__{
      stop: name_from_position(leg.from),
      transit?: transit?(leg.mode),
      route: leg |> Leg.route_id |> parse_route_id,
      trip: leg |> Leg.trip_id |> parse_trip_id,
      departure: leg.start,
      steps: get_steps(leg.mode)
    }
  end

  def name_from_position(%NamedPosition{stop_id: stop_id}) when not is_nil(stop_id) do
    {Stops.Repo.get(stop_id).name, stop_id}
  end
  def name_from_position(%NamedPosition{name: name}) do
    {name, nil}
  end

  defp transit?(%PersonalDetail{}), do: false
  defp transit?(%TransitDetail{}), do: true

  defp get_steps(%PersonalDetail{steps: steps}) do
    Enum.map(steps, &format_personal_step/1)
  end
  defp get_steps(%TransitDetail{intermediate_stop_ids: stop_ids}) do
    stop_ids
    |> Task.async_stream(&Stops.Repo.get/1)
    |> Enum.map(fn {:ok, stop} -> stop.name end)
  end

  defp parse_route_id(:error), do: nil
  defp parse_route_id({:ok, route_id}), do: Routes.Repo.get(route_id)

  defp parse_trip_id(:error), do: nil
  defp parse_trip_id({:ok, trip_id}), do: Schedules.Repo.trip(trip_id)

  defp format_personal_step(step) do
    [
      Step.human_relative_direction(step.relative_direction),
      " onto ",
      step.street_name
    ]
  end
end
