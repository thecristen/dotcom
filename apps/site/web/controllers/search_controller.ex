defmodule Site.SearchController do
  use Site.Web, :controller
  import Site.ResponsivePagination, only: [build: 1]
  import Site.Router.Helpers, only: [search_path: 2]
  alias Plug.Conn

  plug :search_header
  plug :former_site

  @per_page 10

  @spec index(Conn.t, Keyword.t) :: Conn.t
  def index(conn, %{"search" => %{"query" => query} = search_input}) when query != "" do
    conn
    |> assign(:query, query)
    |> assign(:search_input, search_input)
    |> offset()
    |> content_types()
    |> params()
    |> backend_responses()
    |> render_index()
  end
  def index(conn, _params), do: render(conn, "empty_query.html")

  @spec render_index(Conn.t) :: Conn.t
  def render_index(%Conn{assigns: %{error?: true}} = conn), do: render(conn, "error.html")
  def render_index(%Conn{assigns: %{results: []}} = conn), do: render(conn, "no_results.html")
  def render_index(conn) do
    conn
    |> facets()
    |> stats()
    |> link_context()
    |> pagination()
    |> render("index.html")
  end

  @spec search_header(Conn.t, Keyword.t) :: Conn.t
  defp search_header(conn, params) do
    assign(conn, :search_header?, true)
  end

  @spec former_site(Conn.t, Keyword.t) :: Conn.t
  def former_site(conn, _) do
    [host: former_site] = Application.get_env(:site, :former_mbta_site)
    assign(conn, :former_site, former_site)
  end

  @spec link_context(%Conn{assigns: %{params: map}}) :: Conn.t
  def link_context(%Conn{assigns: %{params: params}} = conn) do
    link_context = %{path: search_path(conn, :index), form: "search", params: params}
    assign(conn, :link_context, link_context)
  end

  @spec pagination(%Conn{assigns: %{stats: map}}) :: Conn.t
  def pagination(%Conn{assigns: %{stats: stats}} = conn) do
    pagination = build(stats)
    assign(conn, :pagination, pagination)
  end

  @spec backend_responses(%Conn{assigns: %{query: String.t, offset: integer, content_types: [String.t]}}) :: Conn.t
  def backend_responses(%Conn{assigns: %{query: query, offset: offset, content_types: []}} = conn) do
    case Content.Repo.search(query, offset, []) do
      {:ok, response} ->
        conn
        |> assign(:response, response)
        |> assign(:results, response.results)
        |> assign(:facet_response, response)
      {:error, _} ->
        assign(conn, :error?, true)
    end
  end
  def backend_responses(%Conn{assigns: %{query: query, offset: offset, content_types: content_types}} = conn) do
    response = Task.async(fn -> Content.Repo.search(query, offset, content_types) end)
    facets_response = Task.async(fn -> Content.Repo.search(query, offset, []) end)
    case {Task.await(response), Task.await(facets_response)} do
      {{:ok, response}, {:ok, facet_response}} ->
        conn
        |> assign(:response, response)
        |> assign(:results, response.results)
        |> assign(:facet_response, facet_response)
      {_, _} -> assign(conn, :error?, true)
    end
  end

  @spec stats(%Conn{assigns: %{response: %{count: integer}, offset: integer}}) :: Conn.t
  def stats(%Conn{assigns: %{response: %{count: count}, offset: offset}} = conn) do
    stats = %{total: count,
      per_page: @per_page,
      offset: offset,
      showing_from: (offset * @per_page) + 1,
      showing_to: min((offset * @per_page) + @per_page, count)
    }
    assign(conn, :stats, stats)
  end

  @spec facets(%Conn{assigns: %{facet_response: %Content.Search{content_types: Keyword.t},
                               content_types: [String.t]}}) :: Conn.t
  defp facets(%Conn{assigns: %{facet_response: %Content.Search{content_types: response_types},
                               content_types: content_types}} = conn) do
    facets = "content_type"
    |> build_facet(response_types, content_types)
    |> Map.merge(build_facet("year", Keyword.new, []))
    assign(conn, :facets, facets)
  end

  @spec build_facet(String.t, Keyword.t, [String.t]) :: map
  defp build_facet(type, facet_data, user_selections) do
    Map.put(%{}, type, Enum.map(facet_data, & do_build_facet(&1, type, user_selections)))
  end

  @spec do_build_facet({String.t, integer}, String.t, [String.t]) :: map
  defp do_build_facet({value, count}, type, input) do
    %{label: facet_label(type, value),
      value: value,
      active?: Enum.member?(input, value),
      count: count}
  end

  @spec facet_label(String.t, String.t) :: String.t
  defp facet_label("content_type", "event"), do: "Event"
  defp facet_label("content_type", "landing_page"), do: "Main Page"
  defp facet_label("content_type", "news_entry"), do: "News"
  defp facet_label("content_type", "page"), do: "Page"
  defp facet_label("content_type", "person"), do: "Person"

  @spec params(Conn.t) :: Conn.t
  defp params(%Conn{assigns: %{search_input: search_input}} = conn) do
    params = %{"[query]" => Map.get(search_input, "query", ""), "[offset]" => Map.get(search_input, "offset", "0")}
    |> Map.merge(convert_filter_to_param(search_input, "content_type"))
    |> Map.merge(convert_filter_to_param(search_input, "year"))
    assign(conn, :params, params)
  end

  @spec offset(Conn.t) :: Conn.t
  defp offset(%Conn{assigns: %{search_input: search_input}} = conn) do
    input = Map.get(search_input, "offset", "0")
    offset = case Integer.parse(input) do
      :error -> 0
      {offset, _} -> offset
    end
    assign(conn, :offset, offset)
  end

  @spec content_types(Conn.t) :: Conn.t
  def content_types(%Conn{assigns: %{search_input: search_input}} = conn) do
    content_types = search_input
    |> Map.get("content_type", %{})
    |> Map.keys()
    assign(conn, :content_types, content_types)
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
