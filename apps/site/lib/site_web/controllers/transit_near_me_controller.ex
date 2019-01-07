defmodule SiteWeb.TransitNearMeController do
  use SiteWeb, :controller
  plug(SiteWeb.Plugs.TransitNearMe)

  def index(conn, _params) do
    if Laboratory.enabled?(conn, :transit_near_me_redesign) do
      render(conn, "index.html", breadcrumbs: [Breadcrumb.build("Transit Near Me")])
    else
      render_404(conn)
    end
  end
end
