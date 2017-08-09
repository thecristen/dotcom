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
    steps: []
  ]

  @type t :: %__MODULE__{
    stop: name_and_id,
    transit?: boolean,
    route: Routes.Route.t | nil,
    trip: Schedules.Trip.t | nil,
    departure: DateTime.t,
    steps: [step]
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
    %__MODULE__{
      stop: name_from_position(leg.from, opts[:stop_mapper]),
      transit?: Leg.transit?(leg),
      route: leg |> Leg.route_id |> parse_route_id(opts[:route_mapper]),
      trip: leg |> Leg.trip_id |> parse_trip_id(opts[:trip_mapper]),
      departure: leg.start,
      steps: get_steps(leg.mode, opts[:stop_mapper])
    }
  end

  @spec name_from_position(NamedPosition.t, stop_mapper) :: {String.t, String.t}
  def name_from_position(named_position, stop_mapper \\ &Stops.Repo.get/1)
  def name_from_position(%NamedPosition{stop_id: stop_id, name: name}, stop_mapper) when not is_nil(stop_id) do
    case stop_mapper.(stop_id) do
      nil -> {name, stop_id}
      stop -> {stop.name, stop_id}
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
end
