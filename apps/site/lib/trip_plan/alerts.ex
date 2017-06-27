defmodule Site.TripPlan.Alerts do
  @moduledoc """
  Alert matching for itineraries returned from the trip_plan application

  For each itinerary, we want to return relevant alerts:
  * on the routes they'll be travelling
  * at the stops they'll be interacting with
  * at the times they'll be travelling
  """
  alias TripPlan.{Itinerary, Leg, TransitDetail}
  alias Alerts.Alert
  alias Alerts.InformedEntity, as: IE

  @doc "Filters a list of Alerts to those relevant to the Itinerary"
  @spec filter_for_itinerary([Alert.t], Itinerary.t) :: [Alert.t]
  def filter_for_itinerary(alerts, itinerary) do
    Alerts.Match.match(alerts, entities(itinerary), itinerary.start)
  end

  @spec entities(Itinerary.t) :: [IE.t]
  defp entities(itinerary) do
    itinerary.legs
    |> Enum.flat_map(&leg_entities/1)
    |> Enum.uniq
  end

  defp leg_entities(%Leg{from: from, to: to, mode: mode}) do
    mode_entities(mode)
  end

  defp mode_entities(%TransitDetail{route_id: route_id, trip_id: trip_id}) do
    [%IE{route: route_id}]
  end
  defp mode_entities(_) do
    []
  end
end
