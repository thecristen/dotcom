defmodule Site.AlertController do
  use Site.Web, :controller

  plug Site.Plugs.Route
  plug Site.Plugs.Alerts

  def index(conn, _params) do
    conn
    |> render("index.html")
  end

  def show(conn, %{"id" => alert_id}) do
    conn
    |> render_alert(Alerts.Repo.by_id(alert_id))
  end

  defp render_alert(conn, nil) do
    conn
    |> put_status(:not_found)
    |> render("expired.html")
  end
  defp render_alert(conn, alert) do
    conn
    |> assign(:alerts, [alert])
    |> assign(:notices, [])
    |> render("index.html")
  end
end
