defmodule Content.Repo do
  require Logger
  @moduledoc """

  Interface for the content CMS. Returns a variety of content
  related structs, like %Content.Event{} or %Content.BasicPage{}

  """

  use RepoCache, ttl: :timer.minutes(1)

  @cms_api Application.get_env(:content, :cms_api)

  @spec get_page(String.t, map) :: Content.Page.t | nil
  def get_page(path, query_params \\ %{}) do
    query_params = Map.delete(query_params, "from") # remove tracking

    case view_or_preview(path, query_params) do
      {:ok, api_data} -> Content.Page.from_api(api_data)
      _ -> nil
    end
  end

  @spec news(Keyword.t) :: [Content.NewsEntry.t] | []
  def news(opts \\ []) do
    case @cms_api.view("/news", opts) do
      {:ok, api_data} -> Enum.map(api_data, &Content.NewsEntry.from_api/1)
      _ -> []
    end
  end

  @spec news_entry(integer) :: Content.NewsEntry.t | :not_found
  def news_entry(id) do
    case news(id: id) do
      [record] -> record
      _ -> :not_found
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
    case @cms_api.view("/recent-news", opts) do
      {:ok, api_data} -> Enum.map(api_data, &Content.NewsEntry.from_api/1)
      _ -> []
    end
  end

  @spec events(Keyword.t) :: [Content.Event.t]
  def events(opts \\ []) do
    case @cms_api.view("/events", opts) do
      {:ok, api_data} -> Enum.map(api_data, &Content.Event.from_api/1)
      _ -> []
    end
  end

  @spec event(String.t) :: Content.Event.t | :not_found
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
    case @cms_api.view("/api/projects", opts) do
      {:ok, api_data} -> Enum.map(api_data, &Content.Project.from_api/1)
      _ -> []
    end
  end

  @spec project(integer) :: Content.Project.t | :not_found
  def project(id) do
    case projects([id: id]) do
      [record | _] -> record
      _ -> :not_found
    end
  end

  @spec project_updates(Keyword.t) :: [Content.ProjectUpdate.t]
  def project_updates(opts \\ []) do
    case @cms_api.view("/api/project-updates", opts) do
      {:ok, api_data} -> Enum.map(api_data, &Content.ProjectUpdate.from_api/1)
      _ -> []
    end
  end

  @spec project_update(integer) :: Content.ProjectUpdate.t | :not_found
  def project_update(id) do
    case project_updates([id: id]) do
      [record | _] -> record
      _ -> :not_found
    end
  end

  @spec whats_happening() :: [Content.WhatsHappeningItem.t]
  def whats_happening do
    cache [], fn _ ->
      case @cms_api.view("/whats-happening", []) do
        {:ok, api_data} -> Enum.map(api_data, &Content.WhatsHappeningItem.from_api/1)
        _ -> []
      end
    end
  end

  @spec important_notice() :: Content.ImportantNotice.t | nil
  def important_notice do
    cached_value = cache [], fn _ ->
      case @cms_api.view("/important-notices", []) do
        {:ok, [api_data]} -> Content.ImportantNotice.from_api(api_data)
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
    with {:ok, api_data} <- @cms_api.view("/api/search", params) do
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
    case @cms_api.view("/api/route-pdfs/#{route_id}", []) do
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

  @spec view_or_preview(String.t, map) :: {:ok, map()} | {:error, String.t}
  defp view_or_preview(path, params) do
    with %{"preview" => _, "vid" => vid} <- params do
      path
      |> @cms_api.view([])
      |> get_node_id()
      |> @cms_api.preview()
      |> get_revision(vid)
      |> preview_links()
    else
      _ ->
        path = case params do
          %{"id" => old_site_page_id} -> path <> URI.encode_www_form("?id=#{old_site_page_id}")
          _ -> path
        end
        @cms_api.view(path, [])
    end
  end

  @spec get_revision({:error, any} | {:ok, [map]}, String.t) :: {:error, String.t} | {:ok, map}
  def get_revision({:error, err}, _), do: {:error, err}
  def get_revision({:ok, []}, _), do: {:error, "No results"}
  def get_revision({:ok, revisions}, revision_id) when is_list(revisions) do
    case revision_id do
      "latest" -> {:ok, List.first(revisions)}
      _ ->
        with {vid, ""} <- Integer.parse(revision_id) do
          case Enum.find(revisions, fn %{"vid" => [%{"value" => id}]} -> id == vid end) do
            nil -> {:error, "Revision not found"}
            revision -> {:ok, revision}
          end
        else
          _ -> {:error, "Invalid revision request"}
      end
    end
  end

  @spec get_node_id({:error, String.t} | {:ok, map}) :: {:error, String.t} | integer
  def get_node_id({:error, err}), do: {:error, err}
  def get_node_id({:ok, content}) do
    get_in content, ["nid", Access.at(0), "value"]
  end

  @spec preview_links({:error, String.t} | {:ok, map}) :: {:error, String.t} | {:ok, map}
  def preview_links({:error, err}), do: {:error, err}
  def preview_links({:ok, content}) do
    {:ok, content}
  end
end
