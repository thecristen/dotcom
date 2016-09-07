defmodule Site.Plugs.Route do
  @moduledoc """

  Assigns @route based on a `route` parameter in the conn.

  """
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(%{params: %{"route" => route_id}} = conn, []) do
    conn
    |> assign(:route, Routes.Repo.get(route_id))
  end
  def call(conn, []) do
    conn
    |> assign(:route, nil)
  end
end
