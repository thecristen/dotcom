defmodule Site.Plugs.Route do
  @moduledoc """

  Assigns @route based on a `route` parameter in the conn.

  """
  import Plug.Conn, only: [assign: 3, put_status: 2, halt: 1]
  import Phoenix.Controller, only: [render: 4]

  def init([]), do: []

  def call(%{params: %{"route" => route_id}} = conn, []) do
    case Routes.Repo.get(route_id) do
      nil ->
        halt_not_found(conn)
      route ->
        assign(conn, :route, route)
    end
  end

  defp halt_not_found(conn) do
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
    |> halt
  end
end
