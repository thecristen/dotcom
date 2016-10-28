defmodule Site.HowToPayController do
  use Site.Web, :controller

  def index(conn, _params) do
    render(conn, "how_to_pay.html", mode: :subway)
  end

  for mode <- [:commuter, :bus, :subway, :ferry, :the_ride] do
    def unquote(mode)(conn, _params) do
       render(conn, "how_to_pay.html", mode: unquote(mode))
    end
  end
end
