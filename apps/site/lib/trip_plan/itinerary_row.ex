defmodule Site.TripPlan.ItineraryRow do
  alias TripPlan.{PersonalDetail, TransitDetail, NamedPosition, Leg}
  alias TripPlan.PersonalDetail.Step
  alias Routes.Route

  @typep name_and_id :: {String.t, String.t | nil}
  @typep step :: String.t

  @default_opts [
    stop_mapper: &Stops.Repo.get/1,
    route_mapper: &Routes.Repo.get/1,
    trip_mapper: &Schedules.Repo.trip/1
  ]

  defstruct [
    stop: {nil, nil},
    route: nil,
    trip: nil,
    departure: DateTime.from_unix!(-1),
    transit?: false,
    steps: [],
    additional_routes: []
  ]

  @type t :: %__MODULE__{
    stop: name_and_id,
    transit?: boolean,
    route: Route.t | nil,
    trip: Schedules.Trip.t | nil,
    departure: DateTime.t,
    steps: [step],
    additional_routes: [Route.t]
  }

  @type route_mapper :: (Routes.Route.id_t -> Routes.Route.t | nil)
  @type stop_mapper :: (Stops.Stop.id_t -> Stops.Stop.t | nil)
  @type trip_mapper :: (Schedules.Trip.id_t -> Schedules.Trip.t | nil)

  def route_id(%__MODULE__{route: %Route{id: id}}), do: id
  def route_id(_row), do: nil

  def route_type(%__MODULE__{route: %Route{type: type}}), do: type
  def route_type(_row), do: nil

  def route_name(%__MODULE__{route: %Route{name: name}}), do: name
  def route_name(_row), do: nil

  @doc """
  Builds an ItineraryRow struct from the given leg and options
  Possible Options are:
    * route_mapper
    * stop_mapper
    * trip_mapper
  """
  @spec from_leg(Leg.t, Keyword.t) :: t
  def from_leg(leg, user_opts \\ []) do
    opts = Keyword.merge(@default_opts, user_opts)
    trip = leg |> Leg.trip_id |> parse_trip_id(opts[:trip_mapper])
    route = leg |> Leg.route_id |> parse_route_id(opts[:route_mapper])
    stop = name_from_position(leg.from, opts[:stop_mapper])
    %__MODULE__{
      stop: stop,
      transit?: Leg.transit?(leg),
      route: route,
      trip: trip,
      departure: leg.start,
      steps: get_steps(leg.mode, opts[:stop_mapper]),
      additional_routes: get_additional_routes(route, trip, leg, stop, opts)
    }
  end

  @spec name_from_position(NamedPosition.t, stop_mapper) :: {String.t, String.t}
  def name_from_position(named_position, stop_mapper \\ &Stops.Repo.get/1)
  def name_from_position(%NamedPosition{stop_id: stop_id, name: name}, stop_mapper) when not is_nil(stop_id) do
    case stop_mapper.(stop_id) do
      nil -> {name, stop_id}
      stop -> {stop.name, stop.id}
    end
  end
  def name_from_position(%NamedPosition{name: name}, _stop_mapper) do
    {name, nil}
  end

  @spec get_steps(TripPlan.Leg.mode, stop_mapper) :: [iodata]
  defp get_steps(%PersonalDetail{steps: steps}, _stop_mapper) do
    Enum.map(steps, &format_personal_step/1)
  end
  defp get_steps(%TransitDetail{intermediate_stop_ids: stop_ids}, stop_mapper) do
    for {:ok, stop} <- Task.async_stream(stop_ids, stop_mapper), stop do
      stop.name
    end
  end

  @spec parse_route_id(:error | {:ok, String.t}, route_mapper) :: Routes.Route.t | nil
  defp parse_route_id(:error, _route_mapper), do: nil
  defp parse_route_id({:ok, route_id}, route_mapper), do: route_mapper.(route_id)

  @spec parse_trip_id(:error | {:ok, String.t}, trip_mapper) :: Schedules.Trip.t | nil
  defp parse_trip_id(:error, _trip_mapper), do: nil
  defp parse_trip_id({:ok, trip_id}, trip_mapper), do: trip_mapper.(trip_id)

  defp format_personal_step(step) do
    [
      Step.human_relative_direction(step.relative_direction),
      " onto ",
      step.street_name
    ]
  end

  @spec get_additional_routes(Route.t, Schedules.Trip.t, Leg.t, name_and_id, Keyword.t) :: [Route.t]
  defp get_additional_routes(%Route{id: "Green" <> _line = route_id}, trip, leg, {_name, from_stop_id}, opts)
  when not is_nil(trip) do
    stop_mapper = opts[:stop_mapper]
    route_mapper = opts[:route_mapper]
    stop_pairs = GreenLine.stops_on_routes(trip.direction_id)
    {_to_stop_name, to_stop_id} = name_from_position(leg.to, stop_mapper)
    available_routes(route_id, from_stop_id, to_stop_id, stop_pairs, route_mapper)
  end
  defp get_additional_routes(_route, _trip, _leg, _from, _stop_mapper), do: []

  defp available_routes(current_route_id, from_stop_id, to_stop_id, stop_pairs, route_mapper) do
    GreenLine.branch_ids()
    |> List.delete(current_route_id)
    |> Enum.filter(&both_stops_on_route?(&1, from_stop_id, to_stop_id, stop_pairs))
    |> Enum.map(route_mapper)
  end

  defp both_stops_on_route?(route_id, from_stop_id, to_stop_id, stop_pairs) do
    GreenLine.stop_on_route?(from_stop_id, route_id, stop_pairs) &&
    GreenLine.stop_on_route?(to_stop_id, route_id, stop_pairs)
  end
end
