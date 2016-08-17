defmodule Site.ScheduleController.Alerts do
  use Site.Web, :controller

  import Site.ScheduleController.Defaults
  import Site.ScheduleController.Helpers

  def alerts(conn, %{"alert" => alert_id}) do
    conn
    |> default_assigns
    |> render_alert(Alerts.Repo.by_id(alert_id))
  end
  def alerts(conn, _params) do
    conn
    |> default_assigns
    |> assign_route(conn.params["route"])
    |> assign_alerts
    |> assign_selected_trip
    |> await_assign_all
    |> assign_datetime
    |> route_alerts
    |> stop_alerts
    |> trip_alerts
    |> consolidate_alerts
    |> assign(:suffix, "")
    |> render("alert_list.html")
  end

  # Merge all alerts for the route, trip, and stop, and assign them to :alerts.
  defp consolidate_alerts(
    %{assigns: %{
         :trip_alerts => trip_alerts,
         :route_alerts => route_alerts,
         :stop_alerts => stop_alerts}
    } = conn) do
    all_alerts = [trip_alerts || [], route_alerts || [], stop_alerts || []]
    |> Enum.concat
    |> Enum.uniq

    conn
    |> assign(:alerts, all_alerts)
  end

  defp render_alert(conn, nil) do
    conn
    |> put_status(:not_found)
    |> render("expired_alert.html")
  end
  defp render_alert(conn, alert) do
    conn
    |> assign(:alerts, [alert])
    |> render("alert_list.html")
  end
end
