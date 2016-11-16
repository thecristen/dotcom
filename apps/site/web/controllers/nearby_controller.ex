defmodule Site.NearbyController do
  use Site.Web, :controller

  def index(conn, %{"position" => %{"latitude" => latitude, "longitude" => longitude}}) do
    stops = case {Float.parse(latitude), Float.parse(longitude)} do
              {{latitude, ""}, {longitude, ""}} -> Stops.Repo.closest({latitude, longitude})
              _ -> []
            end
    render(conn, "index.html", stops: stops)
  end
  def index(conn, _params) do
    render(conn, "index.html", stops: [])
  end
end
