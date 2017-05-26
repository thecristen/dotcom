defmodule TripPlan.Api.MockPlanner do
  @behaviour TripPlan.Api

  alias TripPlan.{Itinerary, NamedPosition, Leg, PersonalDetail, TransitDetail}

  @max_distance 1000
  @max_duration 30 * 60

  def plan(from, to, opts) do
    start = DateTime.utc_now()
    duration = :rand.uniform(@max_duration)
    stop = Timex.shift(start, seconds: duration)
    midpoint_stop = random_stop()
    midpoint_time = Timex.shift(start, seconds: Integer.floor_div(duration, 2))
    itineraries = [
      %Itinerary{
        start: start,
        stop: stop,
        legs: [
          personal_leg(from, midpoint_stop, start, midpoint_time),
          transit_leg(midpoint_stop, to, midpoint_time, stop)
        ]
      }
    ]
    send self(), {:planned_trip, {from, to, opts}, {:ok, itineraries}}
    {:ok, itineraries}
  end

  def random_stop do
    stop_id = Enum.random(~w"place-sstat place-north place-bbsta"s)
    stop = Stops.Repo.get!(stop_id)
    %NamedPosition{
      name: stop.name,
      stop_id: stop_id,
      latitude: stop.latitude,
      longitude: stop.longitude
    }
  end

  def personal_leg(from, to, start, stop) do
    distance = :rand.uniform() * @max_distance
    %Leg{
      start: start,
      stop: stop,
      from: from,
      to: to,
      mode: %PersonalDetail{
        distance: distance,
        type: Enum.random(~w(walk drive)a),
        steps: [random_step(), random_step()]
      }
    }
  end

  def random_step do
    distance = :rand.uniform() * @max_distance
    absolute_direction = Enum.random(~w(north east south west)a)
    relative_direction = Enum.random(~w(left right depart continue)a)
    street_name = "Random Street"
    %PersonalDetail.Step{
      distance: distance,
      relative_direction: relative_direction,
      absolute_direction: absolute_direction,
      street_name: street_name
    }
  end

  def transit_leg(from, to, start, stop) do
    route_id = Enum.random(~w(1 Blue CR-Lowell)s)
    schedules = Schedules.Repo.by_route_ids([route_id], stop_sequences: :first)
    trip_id = List.first(schedules).trip.id
    %Leg{
      start: start,
      stop: stop,
      from: from,
      to: to,
      mode: %TransitDetail{
        route_id: route_id,
        trip_id: trip_id
      }
    }
  end
end
