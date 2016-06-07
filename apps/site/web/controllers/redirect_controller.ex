defmodule Site.RedirectController do
  use Site.Web, :controller

  def show(conn, %{"path" => redirect}) do
    render(conn, "show.html", redirect: redirect)
  end
end
