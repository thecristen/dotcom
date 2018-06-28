defmodule SiteWeb.StyleGuideController do
  use SiteWeb, :controller

  def index(conn, _) do
    conn
    |> put_status(301)
    |> redirect(external: "https://projects.invisionapp.com/dsm/mbta-customer-technology/digital-style-guide")
  end
end
