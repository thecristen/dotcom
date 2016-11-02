defmodule Site.AboutController do
  use Site.Web, :controller

  def index(conn, _params) do
    conn
    |> render("about_hub.html")
  end
end
