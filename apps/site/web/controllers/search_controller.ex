defmodule Site.SearchController do
  use Site.Web, :controller
  import Site.ResponsivePagination, only: [build: 1]
  import Site.Router.Helpers, only: [search_path: 2]
  alias Plug.Conn
  alias Content.Search.Facets

  plug :search_header
  plug :former_site

  @per_page 10

  @spec index(Conn.t, Keyword.t) :: Conn.t
  def index(conn, %{"search" => %{"query" => query} = search_input}) when query != "" do
    offset = offset(search_input)
    content_types = content_types(search_input)
    case Facets.facet_responses(query, offset, content_types) do
      :error -> render(conn, "error.html")
      {response, facet_response} -> conn
        |> assign(:query, query)
        |> assign_facets(facet_response, content_types)
        |> assign(:results, response.results)
        |> render_index(offset, response.count, search_input)
    end
  end
  def index(conn, _params), do: render(conn, "empty_query.html")

  @spec render_index(Conn.t, integer, integer, map) :: Conn.t
  defp render_index(%Conn{assigns: %{results: []}} = conn, _, _, _), do: render(conn, "no_results.html")
  defp render_index(conn, offset, count, search_input) do
    conn
    |> stats(offset, count)
    |> link_context(search_input)
    |> pagination()
    |> render("index.html")
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
