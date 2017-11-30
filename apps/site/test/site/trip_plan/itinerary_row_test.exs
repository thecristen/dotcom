defmodule TripPlan.ItineraryRowTest do
  use ExUnit.Case, async: true

  import Site.TripPlan.ItineraryRow
  alias Site.TripPlan.ItineraryRow
  alias Routes.Route
  alias Alerts.{Alert, InformedEntity}

  describe "route_id/1" do
    test "returns the route id when a route is present" do
      row = %ItineraryRow{route: %Route{id: "route"}}

      assert route_id(row) == "route"
    end

    test "returns nil when a route is not present" do
      row = %ItineraryRow{route: nil}

      refute route_id(row)
    end
  end

  describe "route_type/1" do
    test "returns the route type when a route is present" do
      row = %ItineraryRow{route: %Route{type: 0}}

      assert route_type(row) == 0
    end

    test "returns nil when a route is not present" do
      row = %ItineraryRow{route: nil}

      refute route_type(row)
    end
  end

  describe "route_name/1" do
    test "returns the route name when a route is present" do
      row = %ItineraryRow{route: %Route{name: "Red Line"}}

      assert route_name(row) == "Red Line"
    end

    test "returns nil when a route is not present" do
      row = %ItineraryRow{route: nil}

      refute route_name(row)
    end
  end

  describe "fetch_alerts/2" do
    @itinerary_row %ItineraryRow{
      stop: {"stop name", "stopid"},
      route: %Routes.Route{id: "routeid", type: 0},
      trip: %Schedules.Trip{id: "tripid"},
      departure: DateTime.from_unix!(2),
      transit?: true,
      steps: [],
      additional_routes: []
    }

    test "shows alert associated with stop" do
      alert = Alert.new([
        informed_entity: [%InformedEntity{
          route: "routeid",
          route_type: 0,
          stop: "stopid",
          trip: nil,
          direction_id: nil
        }],
        active_period: [{DateTime.from_unix!(1), nil}]
      ])
      assert fetch_alerts(@itinerary_row, [alert]).alerts == [alert]
    end

    test "shows alert for the whole route" do
      alert = Alert.new([
        informed_entity: [%InformedEntity{
          route: "routeid",
          route_type: 0,
          stop: nil,
          trip: nil,
          direction_id: nil
        }],
        active_period: [{DateTime.from_unix!(1), nil}]
      ])
      assert fetch_alerts(@itinerary_row, [alert]).alerts == [alert]
    end

    test "doesn't show alert for another stop on the route" do
      alert = Alert.new([
        informed_entity: [%InformedEntity{
          route: "routeid",
          route_type: 0,
          stop: "differentstopid",
          trip: nil,
          direction_id: nil
        }],
        active_period: [{DateTime.from_unix!(1), nil}]
      ])
      assert fetch_alerts(@itinerary_row, [alert]).alerts == []
    end

    test "shows alert associated with trip" do
      alert = Alert.new([
        informed_entity: [%InformedEntity{
          route: "routeid",
          route_type: 0,
          stop: nil,
          trip: "tripid",
          direction_id: 0
        }],
        active_period: [{DateTime.from_unix!(1), nil}]
      ])
      assert fetch_alerts(@itinerary_row, [alert]).alerts == [alert]
    end

    test "doesn't show alert for different trip" do
      alert = Alert.new([
        informed_entity: [%InformedEntity{
          route: "routeid",
          route_type: 0,
          stop: nil,
          trip: "different-tripid",
          direction_id: 0
        }],
        active_period: [{DateTime.from_unix!(1), nil}]
      ])
      assert fetch_alerts(@itinerary_row, [alert]).alerts == []
    end

    test "for a personal row, only shows alerts for the stop" do
      good_alert = Alert.new([
        informed_entity: [
          %InformedEntity{stop: "stopid"}
        ]])
      bad_alert = Alert.update(good_alert, informed_entity: [
            %InformedEntity{stop: "otherstopid"}])
      row = %{@itinerary_row | transit?: false}
      assert fetch_alerts(row, [good_alert, bad_alert]).alerts == [good_alert]
    end

    test "rows without a real stop don't get alerts" do
      alert = Alert.new([
        informed_entity: [
          %InformedEntity{stop: "stopid"}
        ]])
      row = %{@itinerary_row | transit?: false, stop: {"Stop Name", nil}}
      assert fetch_alerts(row, [alert]).alerts == []
    end
  end
end
