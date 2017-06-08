defmodule Site.TripPlanController do
  use Site.Web, :controller

  plug :require_google_maps

  def index(conn, %{"plan" => plan}) do
    query = TripPlan.Query.from_query(plan)
    render(conn, query: query)
  end
  def index(conn, _params) do
    render(conn, :index)
  end

  def require_google_maps(conn, _) do
    assign(conn, :requires_google_maps?, true)
  end
end
