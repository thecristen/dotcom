defmodule Site.ScheduleController.AllRoutes do
  @moduledoc """
  Once @route is set, fetches all the routes with that same type and assigns them
  as @all_routes
  """

  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(%{assigns: %{route: %{type: type}}} = conn, _) do
    type = if type in [0, 1] do
      [0, 1]
    else
      type
    end

    conn
    |> assign(:all_routes, Routes.Repo.by_type(type))
  end
  def call(conn, _) do
    conn
    |> assign(:all_routes, [])
  end
end
