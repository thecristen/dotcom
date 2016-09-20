defmodule Site.AlertController do
  use Site.Web, :controller

  plug Site.Plugs.Route
  plug Site.Plugs.Alerts
  # TODO refactor breadcrumbs into a more generic plug -ps
  plug Site.ScheduleController.RouteBreadcrumbs
  plug :extend_breadcrumbs

  def index(conn, _params) do
    conn
    |> render("index.html")
  end

  def extend_breadcrumbs(%{assigns: %{route: route, breadcrumbs: breadcrumbs}} = conn, []) do
    route_link = schedule_path(conn, :show, route.id, conn.params)
    # replace the last breadcrumb with a link to the schedule
    breadcrumbs = List.replace_at(breadcrumbs, -1, {route_link, List.last(breadcrumbs)})
    # add last entry
    breadcrumbs = breadcrumbs ++ ["Alerts & Notices"]
    assign(conn, :breadcrumbs, breadcrumbs)
  end
end
