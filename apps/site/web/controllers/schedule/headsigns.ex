defmodule Site.ScheduleController.Headsigns do
  @moduledoc """

  For a given route, puts the headsigns into the template as @headsigns.

  """
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(%{assigns: %{route: %{id: route_id}}} = conn, []) do
    conn
    |> assign(:headsigns, Routes.Repo.headsigns(route_id))
  end
  def call(conn, []) do
    conn
    |> assign(:headsigns, %{0 => [], 1 => []})
  end
end
