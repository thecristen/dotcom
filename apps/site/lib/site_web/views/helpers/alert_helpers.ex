defmodule SiteWeb.Views.Helpers.AlertHelpers do
  import SiteWeb.Router.Helpers, only: [line_path: 3]

  def alert_line_show_path(_conn, "Elevator"), do: "/accessibility"
  def alert_line_show_path(_conn, "Escalator"), do: "/accessibility"
  def alert_line_show_path(_conn, "Other"), do: "/accessibility"
  def alert_line_show_path(conn, route_id), do: line_path(conn, :show, route_id)
end
