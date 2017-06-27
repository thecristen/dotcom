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
      {:ok, %{itinerary: itinerary}}
    end

    test "returns an alert if it affects the route", %{itinerary: itinerary} do
      entities = for route_id <- Itinerary.route_ids(itinerary) do
        %IE{route: route_id}
      end
      good_alert = %Alert{
        active_period: [valid_active_period(itinerary)],
        informed_entity: entities
      }
      bad_alert = %{good_alert | informed_entity: [%IE{route: "not_valid"}]}
      assert filter_for_itinerary([good_alert, bad_alert], itinerary) == [good_alert]
    end
  end

  defp valid_active_period(%Itinerary{start: start, stop: stop}) do
    {start, stop}
  end
end
