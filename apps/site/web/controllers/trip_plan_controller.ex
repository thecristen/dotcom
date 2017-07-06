defmodule Site.TripPlanController do
  use Site.Web, :controller
  alias Site.TripPlan.Map, as: TripPlanMap
  alias Site.TripPlan.Alerts, as: TripPlanAlerts
  alias Site.TripPlan.RelatedLink

  plug :require_google_maps
  plug :assign_initial_map, TripPlanMap.initial_map_src()

  @type route_map :: %{optional(Routes.Route.id_t) => Routes.Route.t}
  @type route_mapper :: ((Routes.Route.id_t) -> Routes.Route.t | nil)

  def index(conn, %{"plan" => plan}) do
    query = TripPlan.Query.from_query(plan)
    route_map = with_itineraries(query, %{}, &routes_for_query/1)
    route_mapper = &Map.get(route_map, &1)
    render conn,
      query: query,
      route_map: route_map,
      itinerary_maps: with_itineraries(query, [], &itinerary_maps(&1, route_mapper)),
      related_links: with_itineraries(query, [], &related_links(&1, route_mapper)),
      alerts: with_itineraries(query, [], &alerts(&1, route_mapper))
  end
  def index(conn, _params) do
    render(conn, :index)
  end

  def require_google_maps(conn, _) do
    assign(conn, :requires_google_maps?, true)
  end

  def assign_initial_map(conn, url) do
    assign(conn, :initial_map_src, url)
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

  @spec alerts([TripPlan.Itinerary.t], route_mapper) :: [alert_list] when alert_list: [Alerts.Alert.t]
  defp alerts([], _) do
    []
  end
  defp alerts([first | _] = itineraries, route_mapper) do
    # time here is only used for sorting, so it's okay that the time might
    # not exactly match the alerts
    all_alerts = Alerts.Repo.all(first.start)
    opts = [route_by_id: route_mapper]
    for itinerary <- itineraries do
      TripPlanAlerts.filter_for_itinerary(all_alerts, itinerary, opts)
    end
  end

  defp itinerary_maps(itineraries, route_mapper) do
    Enum.map(itineraries, &TripPlanMap.itinerary_map(&1, route_mapper: route_mapper))
  end

  defp related_links(itineraries, route_mapper) do
    for itinerary <- itineraries do
      RelatedLink.links_for_itinerary(itinerary, route_by_id: route_mapper)
    end
  end
end
