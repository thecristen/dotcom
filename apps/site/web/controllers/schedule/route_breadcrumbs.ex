defmodule Site.ScheduleController.RouteBreadcrumbs do
  @moduledoc "Fetches the route from `conn.assigns` and assigns breadcrumbs."

  import Plug.Conn, only: [assign: 3]
  import Site.Router.Helpers, only: [mode_path: 2]

  def init([]), do: []

  def call(%{assigns: %{route: route}} = conn, []) do
    conn
    |> assign(:breadcrumbs, breadcrumbs(route))
  end

  def breadcrumbs(%{name: name, type: type}) do
    [{mode_path(Site.Endpoint, :index), "Schedules & Maps"},
     route_type_display(type),
     name]
  end

  def route_type_display(type) when type == 0 or type == 1 do
    {mode_path(Site.Endpoint, :subway), "Subway"}
  end
  def route_type_display(2) do
    {mode_path(Site.Endpoint, :commuter_rail), "Commuter Rail"}
  end
  def route_type_display(3) do
    {mode_path(Site.Endpoint, :bus), "Bus"}
  end
  def route_type_display(4) do
    {mode_path(Site.Endpoint, :boat), "Boat"}
  end
end
