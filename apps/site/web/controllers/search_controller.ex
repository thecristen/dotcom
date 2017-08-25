defmodule Site.SearchController do
  use Site.Web, :controller
  alias Site.SearchController.Results
  import Site.ResponsivePagination, only: [build: 1]

  @per_page 10

  def index(conn, _params) do
    [host: former_site] = Application.get_env(:site, :former_mbta_site)
    search_input = Map.get(conn.query_params, "search", %{})
    query = Map.get(search_input, "query", "")
    params = build_params(search_input)
    offset = parse_offset(params["[offset]"])
    {facets, documents, total} = Results.sample_data(search_input)
    stats = %{total: total, per_page: @per_page, offset: offset}
    link_context = %{path: "/search", form: "search", params: params}
    pagination = build(stats)

    conn
    |> assign(:search_header?, true)
    |> render("index.html", facets: facets, documents: documents, pagination: pagination, query: query,
                            former_site: former_site, params: params, link_context: link_context)
  end

  @spec build_params(map) :: map
  defp build_params(search_input) do
    %{"[query]" => Map.get(search_input, "query", ""), "[offset]" => Map.get(search_input, "offset", "0")}
    |> Map.merge(convert_filter_to_param(search_input, "content_type"))
    |> Map.merge(convert_filter_to_param(search_input, "year"))
  end

  @spec parse_offset(String.t) :: integer
  defp parse_offset(input) do
    case Integer.parse(input) do
      :error -> 0
      {offset, _} -> offset
    end
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
