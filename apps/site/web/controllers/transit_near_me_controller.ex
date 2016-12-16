defmodule Site.TransitNearMeController do
  use Site.Web, :controller
  plug Site.Plugs.TransitNearMe

  @doc """
    Handles GET requests both with and without parameters. Calling with an address parameter (String.t) will assign
    make available to the view:
        @stops_with_routes :: [%{stop: %Stops.Stop{}, routes: [%Route{}]}]
  """
  def index(conn, _params) do
    conn
    |> render("index.html", breadcrumbs: ["Transit Near Me"])
  end
end
