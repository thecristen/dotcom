defmodule Site.TripPlanController do
  use Site.Web, :controller

  plug :require_google_maps

  def index(conn, %{"plan" => plan}) do
    query = TripPlan.Query.from_query(plan)
    route_map = routes_for_query(query)

    render(conn, query: query, route_map: route_map)
  end
  def index(conn, _params) do
    render(conn, :index)
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
end
