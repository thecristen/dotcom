defmodule Site.TripPlanController do
  use Site.Web, :controller
  alias Site.TripPlan.Map, as: TripPlanMap
  alias Site.TripPlan.Alerts, as: TripPlanAlerts

  plug :require_google_maps

  @type route_map :: %{optional(Routes.Route.id_t) => Routes.Route.t}

  def index(conn, %{"plan" => plan}) do
    query = TripPlan.Query.from_query(plan)
    route_map = with_itineraries(query, %{}, &routes_for_query/1)
    render conn,
      query: query,
      route_map: route_map,
      itinerary_maps: with_itineraries(query, [], &itinerary_maps(&1, route_map)),
      alerts: with_itineraries(query, [], &alerts(&1, route_map))
  end
  def index(conn, _params) do
    render(conn, :index, initial_map_src: TripPlanMap.initial_map_src())
  end

  def require_google_maps(conn, _) do
    assign(conn, :requires_google_maps?, true)
  end

  defp with_itineraries(query, default, function)
  defp with_itineraries(%TripPlan.Query{itineraries: {:ok, itineraries}}, _default, function) do
    function.(itineraries)
  end
  defp with_itineraries(%TripPlan.Query{}, default, _function) do
    default
  end

  @spec routes_for_query([TripPlan.Itinerary.t]) :: route_map
  defp routes_for_query(itineraries) do
    itineraries
    |> Enum.flat_map(&TripPlan.Itinerary.route_ids/1)
    |> Enum.uniq
    |> Map.new(&{&1, Routes.Repo.get(&1)})
  end

  @spec alerts([TripPlan.Itinerary.t], route_map) :: [alert_list] when alert_list: [Alerts.Alert.t]
  defp alerts([], _) do
    []
  end
  defp alerts([first | _] = itineraries, route_map) do
    # time here is only used for sorting, so it's okay that the time might
    # not exactly match the alerts
    all_alerts = Alerts.Repo.all(first.start)
    opts = [route_by_id: &Map.get(route_map, &1)]
    for itinerary <- itineraries do
      TripPlanAlerts.filter_for_itinerary(all_alerts, itinerary, opts)
    end
  end

  defp itinerary_maps(itineraries, route_map) do
    Enum.map(itineraries, &TripPlanMap.itinerary_map(&1, route_map))
  end
end
