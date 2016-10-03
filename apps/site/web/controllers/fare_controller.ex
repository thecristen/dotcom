defmodule Site.FareController do
  use Site.Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
