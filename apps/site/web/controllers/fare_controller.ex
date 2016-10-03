defmodule Site.FareController do
  use Site.Web, :controller

  def index(conn, _params) do
    fares = Fares.Repo.all()
    render(conn, "index.html", fares: fares)
  end
end
