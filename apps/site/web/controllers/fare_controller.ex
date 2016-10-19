defmodule Site.FareController do
  use Site.Web, :controller

  alias Site.FareController.{Commuter, BusSubway, Ferry}

  defdelegate commuter(conn, params), to: Commuter, as: :index
  defdelegate ferry(conn, params), to: Ferry, as: :index
  defdelegate bus_subway(conn, params), to: BusSubway, as: :index

end
