defmodule Site.FareController do
  use Site.Web, :controller

  alias Site.FareController.{Commuter, BusSubway, Ferry}

  defdelegate commuter(conn, params), to: Commuter, as: :index
  defdelegate ferry(conn, params), to: Ferry, as: :index
  defdelegate bus_subway(conn, params), to: BusSubway, as: :index

  def reduced(conn, _params) do
    render conn, "reduced.html", []
  end

  def charlie_card(conn, _params) do
    render conn, "charlie_card.html", []
  end
end
