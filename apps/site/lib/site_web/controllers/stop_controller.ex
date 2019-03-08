defmodule SiteWeb.StopController do
  @moduledoc """
  Page for display of information about in individual stop or station.
  """
  use SiteWeb, :controller

  def show(conn, %{"stop" => stop}) do
    if Laboratory.enabled?(conn, :stop_page_redesign) do
      render(conn, "show.html", stop: stop)
    else
      render_404(conn)
    end
  end
end
