defmodule Site.FareController do
  use Site.Web, :controller

  defdelegate commuter(conn, params), to: __MODULE__.Commuter, as: :index
end
