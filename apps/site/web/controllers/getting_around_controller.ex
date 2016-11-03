defmodule Site.GettingAroundController do
  use Site.Web, :controller

  def index(conn, _params) do
    conn
    |> render("getting_around.html")
  end
end
