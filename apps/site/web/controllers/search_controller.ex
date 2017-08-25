defmodule Site.SearchController do
  use Site.Web, :controller
  import Site.ResponsivePagination, only: [build: 1]

  @per_page 10

  def index(conn, _params) do
    [host: former_site] = Application.get_env(:site, :former_mbta_site)
    search_input = Map.get(conn.query_params, "search", %{})
    query = Map.get(search_input, "query", "")
    params = build_params(search_input)
    offset = parse_offset(params["[offset]"])
    content_types = convert_content_type_to_list(search_input)
    {response, facet_response} = get_responses(query, offset, content_types)
    facets = build_facets(facet_response, content_types)
    stats = build_stats(response.count, offset)
    link_context = %{path: "/search", form: "search", params: params}
    pagination = build(stats)
    template = if response.results == [], do: "no-results.html", else: "index.html"

    conn
    |> assign(:search_header?, true)
    |> render(template, facets: facets, results: response.results, pagination: pagination, query: query,
                            former_site: former_site, params: params, link_context: link_context, stats: stats)
  end

  @spec get_responses(String.t, integer, [String.t]) :: {Content.Search.t, Content.Search.t}
  def get_responses(query, offset, []) do
    {:ok, response} = Content.Repo.search(query, offset, [])
    {response, response}
  end
  def get_responses(query, offset, content_types) do
    response = Task.async(fn -> Content.Repo.search(query, offset, content_types) end)
    facets_response = Task.async(fn -> Content.Repo.search(query, offset, []) end)
    case {Task.await(response), Task.await(facets_response)} do
      {{:ok, r1}, {:ok, r2}} -> {r1, r2}
    end
  end

  @spec build_stats(integer, integer) :: Site.ResponsivePagination.stats
  def build_stats(count, offset) do
    %{total: count,
      per_page: @per_page,
      offset: offset,
      showing_from: (offset * @per_page) + 1,
      showing_to: min((offset * @per_page) + @per_page, count)
    }
  end

  @spec build_facets(%Content.Search{content_types: Keyword.t}, [String.t]) :: map
  defp build_facets(%Content.Search{content_types: response_types}, content_types) do
    build_facet("content_type", response_types, content_types)
    |> Map.merge(build_facet("year", Keyword.new, []))
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

  @spec convert_content_type_to_list(map) :: [String.t]
  def convert_content_type_to_list(search_input) do
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
