defmodule SiteWeb.SearchController do
  use SiteWeb, :controller
  import Site.ResponsivePagination, only: [build: 1]
  import SiteWeb.Router.Helpers, only: [search_path: 2]
  alias Plug.Conn
  alias Alerts.Alert
  alias Content.Search.Facets

  plug :search_header
  plug :former_site

  @typep id_map :: %{
    required(:stop) => MapSet.t(String.t),
    required(:route) => MapSet.t(String.t)
  }

  @spec index(Conn.t, Keyword.t) :: Conn.t
  def index(conn,
            %{"search" => %{"query" => query} = search_input})
            when query != "" do
    offset = offset(search_input)
    content_types = content_types(search_input)
    conn = assign_js(conn)
    case Facets.facet_responses(query, offset, content_types) do
      :error -> render_error(conn)
      {response, facet_response} -> conn
        |> assign(:query, query)
        |> assign_facets(facet_response, content_types)
        |> assign(:results, response.results)
        |> render_index(offset, response.count, search_input)
    end
  end
  def index(conn, _params) do
    conn
    |> assign_js
    |> assign(:empty_query, true)
    |> render("index.html")
  end

  @spec click(Conn.t, map) :: Conn.t
  def click(conn, params) do
    response = case Algolia.Analytics.click(params) do
      :ok ->
        %{message: "success"}
      {:error, %HTTPoison.Response{} = response} ->
        %{message: "bad_response", body: response.body, status_code: response.status_code}
      {:error, %HTTPoison.Error{reason: reason}} ->
        %{message: "error", reason: reason}
    end
    json(conn, response)
  end

  @spec render_error(Conn.t) :: Conn.t
  defp render_error(conn) do
    conn
    |> assign(:show_error, true)
    |> render("index.html")
  end

  @per_page 10

  @spec render_index(Conn.t, integer, integer, map) :: Conn.t
  defp render_index(%Conn{assigns: %{results: []}} = conn, _, _, _), do: render(conn, "index.html")
  defp render_index(conn, offset, count, search_input) do
    conn
    |> stats(offset, count)
    |> link_context(search_input)
    |> pagination()
    |> render("index.html")
  end

  @spec assign_js(Conn.t) :: Conn.t
  defp assign_js(conn) do
    %{stop: stop_ids, route: route_ids} = get_alert_ids(conn.assigns.date_time)

    conn
    |> assign(:requires_google_maps?, true)
    |> assign(:stops_with_alerts, stop_ids)
    |> assign(:routes_with_alerts, route_ids)
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

  @spec search_header(Conn.t, Keyword.t) :: Conn.t
  defp search_header(conn, _), do: assign(conn, :search_header?, true)

  @spec former_site(Conn.t, Keyword.t) :: Conn.t
  def former_site(conn, _) do
    [host: former_site] = Application.get_env(:site, :former_mbta_site)
    assign(conn, :former_site, former_site)
  end

  @spec link_context(Conn.t, map) :: Conn.t
  defp link_context(conn, search_input) do
    search_params = search_params(search_input)
    link_context = %{path: search_path(conn, :index), form: "search", params: search_params}
    assign(conn, :link_context, link_context)
  end

  @spec pagination(%Conn{assigns: %{stats: map}}) :: Conn.t
  defp pagination(%Conn{assigns: %{stats: stats}} = conn) do
    pagination = build(stats)
    assign(conn, :pagination, pagination)
  end

  @spec assign_facets(Conn.t, %Content.Search{content_types: Keyword.t}, [String.t]) :: Conn.t
  def assign_facets(conn, %Content.Search{content_types: response_types}, content_types) do
    assign(conn, :facets, Facets.build("content_type", response_types, content_types))
  end

  @spec stats(Conn.t, integer, integer) :: Conn.t
  defp stats(conn, offset, count) do
    stats = %{
      total: count,
      per_page: @per_page,
      offset: offset,
      showing_from: (offset * @per_page) + 1,
      showing_to: min((offset * @per_page) + @per_page, count)
    }
    assign(conn, :stats, stats)
  end

  @spec search_params(map) :: map
  defp search_params(search_input) do
    %{"[query]" => Map.get(search_input, "query", ""), "[offset]" => Map.get(search_input, "offset", "0")}
    |> Map.merge(convert_filter_to_param(search_input, "content_type"))
    |> Map.merge(convert_filter_to_param(search_input, "year"))
  end

  @spec offset(map) :: integer
  defp offset(search_input) do
    input = Map.get(search_input, "offset", "0")
    case Integer.parse(input) do
      :error -> 0
      {search_offset, _} -> search_offset
    end
  end

  @spec content_types(map) :: [String.t]
  defp content_types(search_input) do
    search_input
    |> Map.get("content_type", %{})
    |> Map.keys()
  end

  @spec convert_filter_to_param(map, String.t) :: map
  defp convert_filter_to_param(search_input, field) do
    search_input
    |> Map.get(field, %{})
    |> Enum.reduce(%{}, fn({key, _value}, output) ->
      Map.put(output, "[#{field}][#{key}]", "true")
    end)
  end
end
