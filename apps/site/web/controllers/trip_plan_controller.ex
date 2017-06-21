defmodule Site.TripPlanController do
  use Site.Web, :controller
  alias Site.TripPlanController.TripPlanMap

  plug :require_google_maps

  def index(conn, %{"plan" => plan}) do
    query = TripPlan.Query.from_query(plan)
    route_map = routes_for_query(query)

    conn
    |> assign(:query, query)
    |> assign(:route_map, route_map)
    |> assign(:itinerary_maps, itinerary_maps(query))
    |> render
  end
  def index(conn, _params) do
    render(conn, :index, initial_map_src: TripPlanMap.initial_map_src())
  end

  def require_google_maps(conn, _) do
    assign(conn, :requires_google_maps?, true)
  end

  @spec routes_for_query(TripPlan.Query.t) :: %{Routes.Route.id_t => Routes.Route}
  defp routes_for_query(%TripPlan.Query{itineraries: {:ok, itineraries}}) do
    itineraries
    |> Enum.flat_map(&TripPlan.Itinerary.route_ids/1)
    |> Enum.uniq
    |> Map.new(&{&1, Routes.Repo.get(&1)})
  end
  defp routes_for_query(%TripPlan.Query{}) do
    %{}
  end

  defp itinerary_maps(%TripPlan.Query{itineraries: {:ok, itineraries}}) do
    Enum.map(itineraries, &TripPlanMap.itinerary_map_src/1)
  end
  defp itinerary_maps(%TripPlan.Query{}) do
    %{}
  end
end
