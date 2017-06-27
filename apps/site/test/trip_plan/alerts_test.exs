defmodule Site.TripPlan.AlertsTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import Site.TripPlan.Alerts
  alias TripPlan.Itinerary
  alias Alerts.Alert
  alias Alerts.InformedEntity, as: IE

  @from TripPlan.Api.MockPlanner.random_stop
  @to TripPlan.Api.MockPlanner.random_stop
  @date_time ~N[2017-06-27T11:43:00]

  describe "filter_for_itinerary/2" do
    setup do
      {:ok, [itinerary]} = TripPlan.plan(@from, @to, depart_at: @date_time)
      [route_id] = Itinerary.route_ids(itinerary)
      [trip_id] = Itinerary.trip_ids(itinerary)
      {:ok, %{itinerary: itinerary, route_id: route_id, trip_id: trip_id}}
    end

    test "returns an alert if it affects the route", %{itinerary: itinerary, route_id: route_id} do
      good_alert = %Alert{
        active_period: [valid_active_period(itinerary)],
        informed_entity: [%IE{route: route_id}]
      }
      bad_alert = %{good_alert | informed_entity: [%IE{route: "not_valid"}]}
      assert filter_for_itinerary([good_alert, bad_alert], itinerary, opts()) == [good_alert]
    end

    test "returns an alert if it affects the trip", %{itinerary: itinerary, trip_id: trip_id} do
      good_alert = %Alert{
        active_period: [valid_active_period(itinerary)],
        informed_entity: [%IE{trip: trip_id}]
      }
      bad_alert = %{good_alert | informed_entity: [%IE{trip: "not_valid"}]}
      assert filter_for_itinerary([good_alert, bad_alert], itinerary, opts()) == [good_alert]
    end

    test "returns an alert if it affects the route in a direction", %{itinerary: itinerary, route_id: route_id} do
      good_alert = %Alert{
        active_period: [valid_active_period(itinerary)],
        informed_entity: [%IE{route: route_id, direction_id: 1}]
      }
      bad_alert = %{good_alert | informed_entity: [%IE{route: route_id, direction_id: 0}]}
      assert filter_for_itinerary([good_alert, bad_alert], itinerary, opts()) == [good_alert]
    end

    test "returns an alert if it affects the route's type", %{itinerary: itinerary, route_id: route_id} do
      route = route_by_id(route_id)
      good_alert = %Alert{
        active_period: [valid_active_period(itinerary)],
        informed_entity: [%IE{route_type: route.type}]
      }
      bad_alert = %{good_alert | informed_entity: [%IE{route_type: 0}]}
      assert filter_for_itinerary([good_alert, bad_alert], itinerary, opts()) == [good_alert]
    end
  end

  defp valid_active_period(%Itinerary{start: start, stop: stop}) do
    {start, stop}
  end

  defp opts do
    [route_by_id: &route_by_id/1, trip_by_id: &trip_by_id/1]
  end

  defp route_by_id("Blue" = id) do
    %Routes.Route{type: 1, id: id, name: "Subway"}
  end
  defp route_by_id("CR-Lowell" = id) do
    %Routes.Route{type: 2, id: id, name: "Commuter Rail"}
  end
  defp route_by_id("1" = id) do
    %Routes.Route{type: 3, id: id, name: "Bus"}
  end

  defp trip_by_id(trip) do
    %Schedules.Trip{id: trip, direction_id: 1}
  end
end
