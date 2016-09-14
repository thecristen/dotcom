defmodule Site.Plugs.Route do
  @moduledoc """

  Assigns @route based on a `route` parameter in the conn.

  """
  import Plug.Conn, only: [assign: 3, put_status: 2, halt: 1]
  import Phoenix.Controller, only: [render: 4]

  def init(opts), do: Keyword.get(opts, :required, false)

  def call(%{params: %{"route" => route_id}} = conn, required) do
    conn
    |> assign(:route, Routes.Repo.get(route_id))
    |> check_route(required)
  end
  def call(conn, required) do
    conn
    |> assign(:route, nil)
    |> check_route(required)
  end

  defp check_route(%{assigns: %{route: nil}} = conn, true) do
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
    |> halt
  end
  defp check_route(conn, _) do
    conn
  end
end
