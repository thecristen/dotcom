defmodule Content.Repo do
  require Logger
  @moduledoc """

  Interface for the content CMS. Returns a variety of content
  related structs, like %Content.Event{} or %Content.BasicPage{}

  """

  use RepoCache, ttl: :timer.minutes(1)

  @cms_api Application.get_env(:content, :cms_api)

  @spec get_page(String.t, map) :: Content.Page.t | {:error, Content.CMS.error}
  def get_page(path, query_params \\ %{}) do
    case view_or_preview(path, query_params) do
      {:ok, api_data} -> Content.Page.from_api(api_data)
      {:error, error} -> {:error, error}
    end
  end

  @spec get_page_with_encoded_id(String.t, map) :: Content.Page.t | {:error, Content.CMS.error}
  def get_page_with_encoded_id(path, %{"id" => _} = query_params) do
    {id, params} = Map.pop(query_params, "id")
    encoded_id = URI.encode_www_form("?id=#{id}")

    path
    |> Kernel.<>(encoded_id)
    |> get_page(params)
  end

  @spec news(Keyword.t) :: [Content.NewsEntry.t] | []
  def news(opts \\ []) do
    cache opts, fn _ ->
      case @cms_api.view("/cms/news", opts) do
        {:ok, api_data} -> Enum.map(api_data, &Content.NewsEntry.from_api/1)
        _ -> []
      end
    end
  end

  @spec news_entry_by(Keyword.t) :: Content.NewsEntry.t | :not_found
  def news_entry_by(opts) do
    case news(opts) do
     [record] -> record
     [] -> :not_found
    end
  end

  @spec recent_news(Keyword.t) :: [Content.NewsEntry.t]
  def recent_news(opts \\ []) do
    cache opts, fn _ ->
      case @cms_api.view("/cms/recent-news", opts) do
        {:ok, api_data} -> Enum.map(api_data, &Content.NewsEntry.from_api/1)
        _ -> []
      end
    end
  end

  @spec events(Keyword.t) :: [Content.Event.t]
  def events(opts \\ []) do
    case @cms_api.view("/cms/events", opts) do
      {:ok, api_data} -> Enum.map(api_data, &Content.Event.from_api/1)
      _ -> []
    end
  end

  @spec event(integer) :: Content.Event.t | :not_found
  def event(id) do
    case events(id: id) do
      [record] -> record
      _ -> :not_found
    end
  end

  @spec event_by(Keyword.t) :: Content.Event.t | :not_found
  def event_by(opts) do
    case events(opts) do
      [record] -> record
      [] -> :not_found
    end
  end

  @spec projects(Keyword.t) :: [Content.Project.t]
  def projects(opts \\ []) do
    case @cms_api.view("/cms/projects", opts) do
      {:ok, api_data} -> Enum.map(api_data, &Content.Project.from_api/1)
      _ -> []
    end
  end

  @spec project_updates(Keyword.t) :: [Content.ProjectUpdate.t]
  def project_updates(opts \\ []) do
    case @cms_api.view("/cms/project-updates", opts) do
      {:ok, api_data} -> Enum.map(api_data, &Content.ProjectUpdate.from_api/1)
      _ -> []
    end
  end

  @spec whats_happening() :: [Content.WhatsHappeningItem.t]
  def whats_happening do
    cache [], fn _ ->
      case @cms_api.view("/cms/whats-happening", []) do
        {:ok, api_data} -> Enum.map(api_data, &Content.WhatsHappeningItem.from_api/1)
        _ -> []
      end
    end
  end

  @spec banner() :: Content.Banner.t | nil
  def banner do
    cached_value = cache [], fn _ ->
      # Banners were previously called Important Notices
      case @cms_api.view("/cms/important-notices", []) do
        {:ok, [api_data | _]} -> Content.Banner.from_api(api_data)
        {:ok, _} -> :empty
        {:error, _} -> :error
      end
    end
    if cached_value == :empty || cached_value == :error, do: nil, else: cached_value
  end

  @spec create_event(String.t) :: {:ok, Content.Event.t} | {:error, map} | {:error, String.t}
  def create_event(body) do
    with {:ok, api_data} <- @cms_api.post("entity/node", body) do
      {:ok, Content.Event.from_api(api_data)}
    end
  end

  @spec update_event(integer, String.t) :: {:ok, Content.Event.t} | {:error, map} | {:error, String.t}
  def update_event(id, body) do
    with {:ok, api_data} <- @cms_api.update("node/#{id}", body) do
      {:ok, Content.Event.from_api(api_data)}
    end
  end

  @spec create_news_entry(String.t) :: {:ok, Content.NewsEntry.t} | {:error, map} | {:error, String.t}
  def create_news_entry(body) do
    with {:ok, api_data} <- @cms_api.post("entity/node", body) do
      {:ok, Content.NewsEntry.from_api(api_data)}
    end
  end

  @spec update_news_entry(integer, String.t) :: {:ok, Content.NewsEntry.t} | {:error, map} | {:error, String.t}
  def update_news_entry(id, body) do
    with {:ok, api_data} <- @cms_api.update("node/#{id}", body) do
      {:ok, Content.NewsEntry.from_api(api_data)}
    end
  end

  @spec search(String.t, integer, [String.t]) :: any
  def search(query, offset, content_types) do
    params = [q: query, page: offset] ++ Enum.map(content_types, & {:"type[]", &1})
    with {:ok, api_data} <- @cms_api.view("/cms/search", params) do
      {:ok, Content.Search.from_api(api_data)}
    end
  end

  @spec get_route_pdfs(Routes.Route.id_t) :: [Content.RoutePdf.t]
  def get_route_pdfs(route_id) do
    case cache(route_id, &do_get_route_pdfs/1, timeout: :timer.hours(6)) do
      {:ok, pdfs} -> pdfs
      error ->
        _ = Logger.warn fn -> "Error getting pdfs for route #{route_id}. Using default []. Error: #{inspect error}" end
        []
    end
  end

  defp do_get_route_pdfs(route_id) do
    case @cms_api.view("/cms/route-pdfs/#{route_id}", []) do
      {:ok, []} ->
        {:ok, []}
      {:ok, [api_data | _]} ->
        pdfs = api_data
        |> Map.get("field_pdfs")
        |> Enum.map(&Content.RoutePdf.from_api/1)
        {:ok, pdfs}
      error ->
        error
    end
  end

  @spec view_or_preview(String.t, map)
  :: {:ok, map} | {:error, Content.CMS.error}
  defp view_or_preview(_path, %{"preview" => _, "vid" => vid, "nid" => node_id}) do
    case Integer.parse(node_id) do
      {nid, ""} ->
        nid
        |> @cms_api.preview()
        |> get_revision(vid)
      _ ->
        {:error, :not_found} # Invalid or missing node ID
    end
  end
  defp view_or_preview(path, params) do
    @cms_api.view(path, params)
  end

  @spec get_revision({:error, any} | {:ok, [map]}, String.t) :: {:error, String.t} | {:ok, map}
  def get_revision({:error, err}, _), do: {:error, err}
  def get_revision({:ok, []}, _), do: {:error, :not_found} # No results
  def get_revision({:ok, revisions}, revision_id) when is_list(revisions) do
    case revision_id do
      "latest" -> {:ok, List.first(revisions)}
      _ ->
        with {vid, ""} <- Integer.parse(revision_id) do
          case Enum.find(revisions, fn %{"vid" => [%{"value" => id}]} -> id == vid end) do
            nil -> {:error, :not_found} # Revision not found
            revision -> {:ok, revision}
          end
        else
          _ -> {:error, :not_found} # Invalid revision request
      end
    end
  end

  @doc """
  Returns a list of teaser items.

  Opts can include :type, which can be one of:
    :news_entry
    :event
    :project
    :page
    :project_update

  To filter by a route include :route_id, for example:
    "/guides/subway" or just "subway"

  To fetch all items that are NOT of a specific type,
  use [type: _type, type_op: "not in"]

  Opts can also include :items_per_page, which sets
  the number of items to return. Default is 5 items.
  The number can only be 1-10, 20, or 50, otherwise
  it will be ignored.
  """
  @spec teasers(Keyword.t) :: [Content.Teaser.t]
  def teasers(opts \\ []) when is_list(opts) do
    opts
    |> teaser_path()
    |> @cms_api.view(teaser_params(opts))
    |> do_teasers(opts)
  end

  @spec teaser_path(Keyword.t) :: String.t
  defp teaser_path(opts) do
    path = case Enum.into(opts, %{}) do
      %{route_id: route_id, topic: topic} -> "/#{topic}/#{route_id}"
      %{mode: mode, topic: topic} -> "/#{topic}/#{mode}"
      %{topic: topic} -> "/#{topic}"
      %{mode: mode} -> "/#{mode}"
      %{route_id: route_id} -> "/#{route_id}"
    end
    "/cms/teasers#{path}"
  end

  @default_teaser_params %{
    sidebar: 1
  }

  @spec teaser_params(Keyword.t) :: %{
    required(:sidebar) => integer,
    optional(:type) => atom,
    optional(:type_op) => String.t,
    optional(:items_per_page) => 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 20 | 50
  }
  defp teaser_params(opts) do
    Map.merge(@default_teaser_params, Map.new(opts))
  end

  @spec do_teasers({:ok, [map]} | {:error, any}, Keyword.t) :: [Content.Teaser.t]
  defp do_teasers({:ok, teasers}, _) do
    Enum.map(teasers, &Content.Teaser.from_api/1)
  end

  defp do_teasers({:error, error}, opts) do
    _ = [
      "module=#{__MODULE__}",
      "method=teasers",
      "error=" <> inspect(error),
      "opts=#{inspect(opts)}"
    ]
    |> Enum.join(" ")
    |> Logger.warn()

    []
  end
end
