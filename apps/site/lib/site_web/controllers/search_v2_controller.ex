defmodule SiteWeb.SearchV2Controller do
  use SiteWeb, :controller

  def index(conn, _params) do
    if Laboratory.enabled?(conn, :search_v2) do
      render(conn, "index.html")
    else
      render_404(conn)
    end
  end
end
