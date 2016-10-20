defmodule Site.FareController do
  use Site.Web, :controller

  defdelegate commuter(conn, params), to: __MODULE__.Commuter, as: :index
  defdelegate ferry(conn, params), to: __MODULE__.Ferry, as: :index
end
