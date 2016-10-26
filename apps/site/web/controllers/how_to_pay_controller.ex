defmodule Site.HowToPayController do
  use Site.Web, :controller

  def index(conn, _params) do
    render(conn, "how_to_pay.html", mode: nil)
  end

  def commuter(conn, _params) do
    render(conn, "how_to_pay.html", mode: :commuter)
  end

  def bus(conn, _params) do
    render(conn, "how_to_pay.html", mode: :bus)
  end

  def subway(conn, _params) do
    render(conn, "how_to_pay.html", mode: :subway)
  end

  def ferry(conn, _params) do
    render(conn, "how_to_pay.html", mode: :ferry)
  end

  def the_ride(conn, _params) do
    render(conn, "how_to_pay.html", mode: :the_ride)
  end
end
