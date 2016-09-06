defmodule Site.AlertController do
  use Site.Web, :controller

  plug :route

  def index(conn, _params) do
    conn
    |> notices_and_alerts
    |> render("index.html")
  end

  def show(conn, %{"id" => alert_id}) do
    conn
    |> render_alert(Alerts.Repo.by_id(alert_id))
  end

  @doc """

  Used by the schedule view to render a modal with relevant alerts.

  """
  def modal(conn) do
    conn
    |> notices_and_alerts
    |> render_modal
  end

  @doc """

  Renders an inline list of alerts, passed in as the alerts key.

  """
  def inline(_conn, [{:alerts, []}|_]) do
    ""
  end
  def inline(_conn, [{:alerts, nil}|_]) do
    ""
  end
  def inline(_conn, assigns) do
    Site.AlertView.render("inline.html", assigns)
  end

  defp render_modal(%{assigns: %{notices: notices, alerts: alerts} = assigns} = conn) when notices != [] or alerts != [] do
    assigns = assigns
    |> Map.put(:layout, false)
    |> Map.put(:conn, conn)

    Site.AlertView.render("modal.html", assigns)
  end
  defp render_modal(_conn) do
    ""
  end

  defp render_alert(conn, nil) do
    conn
    |> put_status(:not_found)
    |> render("expired.html")
  end
  defp render_alert(conn, alert) do
    conn
    |> assign(:alerts, [alert])
    |> render("index.html")
  end

  defp route(%{assigns: %{route: route}} = conn, _opts) when route != nil do
    conn
  end
  defp route(%{params: %{"route" => route_id}} = conn, _opts) when is_binary(route_id) do
    conn
    |> assign(:route,  Routes.Repo.get(route_id))
  end
  defp route(conn, _opts) do
    conn
    |> assign(:route, nil)
  end

  defp notices_and_alerts(conn) do
    all_alerts = conn
    |> alerts

    date = date(conn.params["date"])

    {current_alerts, upcoming_alerts} = all_alerts
    |> Enum.partition(fn alert -> Alerts.Match.any_time_match?(alert, date) end)

    {notices, alerts} = current_alerts
    |> Enum.partition(&Alerts.Alert.is_notice?/1)

    # put anything upcoming in the notices block, but at the end
    notices = [notices, upcoming_alerts]
    |> Enum.concat
    |> Enum.uniq

    conn
    |> assign(:all_alerts, all_alerts)
    |> assign(:upcoming_alerts, upcoming_alerts)
    |> assign(:notices, notices)
    |> assign(:alerts, alerts)
  end

  defp alerts(%{params: params, assigns: %{route: route}}) do
    params = put_in params["route_type"], route.type

    alerts_from_params(params)
  end
  defp alerts(%{params: params}) do
    alerts_from_params(params)
  end

  defp alerts_from_params(params) do
    base_entity = struct(Alerts.InformedEntity, [
          route_type: params["route_type"],
          route: params["route"],
          trip: params["trip"],
          direction_id: direction_id(params["direction_id"])
        ])

    entities = [params["origin"], params["dest"]]
    |> Enum.uniq
    |> Enum.map(fn stop -> %{base_entity | stop: stop} end)

    Alerts.Repo.all
    |> Alerts.Match.match(entities)
    |> sort
  end

  defp direction_id(nil) do
    nil
  end
  defp direction_id(str) when is_binary(str) do
    case Integer.parse(str) do
      {id, ""} -> id
      _ -> nil
    end
  end

  defp date(nil) do
    Util.today
  end
  defp date(str) when is_binary(str) do
    case Timex.parse(str, "{ISOdate}") do
      {:ok, value} -> Timex.to_date(value)
      _ -> Util.today
    end
  end

  defp sort(alerts) do
    alerts
    |> Enum.sort_by(&(- Timex.to_unix(&1.updated_at)))
  end
end
