defmodule SiteWeb.SearchV2Controller do
  use SiteWeb, :controller
  alias Alerts.Alert

  @typep id_map :: %{
    required(:stop) => MapSet.t(String.t),
    required(:route) => MapSet.t(String.t)
  }

  def index(conn, _params) do
    if Laboratory.enabled?(conn, :search_v2) do
      %{stop: stop_ids, route: route_ids} = get_alert_ids(conn.assigns.date_time)

      conn
      |> assign(:requires_google_maps?, true)
      |> assign(:stops_with_alerts, stop_ids)
      |> assign(:routes_with_alerts, route_ids)
      |> render("index.html")
    else
      render_404(conn)
    end
  end

  @spec get_alert_ids(DateTime.t, (DateTime.t -> [Alert.t])) :: id_map
  def get_alert_ids(%DateTime{} = dt, alerts_repo_fn \\ &Alerts.Repo.all/1) do
    dt
    |> alerts_repo_fn.()
    |> Enum.reject(& Alert.is_notice?(&1, dt))
    |> Enum.reduce(%{stop: MapSet.new(), route: MapSet.new()}, &get_entity_ids/2)
  end

  @spec get_entity_ids(Alert.t, id_map) :: id_map
  defp get_entity_ids(alert, acc) do
    acc
    |> do_get_entity_ids(alert, :stop)
    |> do_get_entity_ids(alert, :route)
  end

  @spec do_get_entity_ids(id_map, Alert.t, :stop | :route) :: id_map
  defp do_get_entity_ids(acc, %Alert{} = alert, key) do
    alert
    |> Alert.get_entity(key)
    |> Enum.reduce(acc, & add_id_to_set(&2, key, &1))
  end

  @spec add_id_to_set(id_map, :stop | :route, String.t | nil) :: id_map
  defp add_id_to_set(acc, _set_name, nil) do
    acc
  end
  defp add_id_to_set(acc, set_name, <<id::binary>>) do
    Map.update!(acc, set_name, & MapSet.put(&1, id))
  end
end
