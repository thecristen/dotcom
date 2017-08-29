defmodule Content.Repo do
  @moduledoc """

  Interface for the content CMS. Returns a variety of content
  related structs, like %Content.Event{} or %Content.BasicPage{}

  """

  use RepoCache, ttl: :timer.minutes(1)

  @cms_api Application.get_env(:content, :cms_api)

  @spec news(Keyword.t) :: [Content.NewsEntry.t] | []
  def news(opts \\ []) do
    case @cms_api.view("/news", opts) do
      {:ok, api_data} -> Enum.map(api_data, &Content.NewsEntry.from_api/1)
      _ -> []
    end
  end

  @spec news_entry!(integer) :: Content.NewsEntry.t | no_return
  def news_entry!(id) do
    case news(id: id) do
      [news_entry] -> news_entry
      _ -> raise Content.NoResultsError
    end
  end

  def news_entry_by(opts) do
    case news(opts) do
     [record] -> record
     [] -> nil
    end
  end

  @spec recent_news(Keyword.t) :: [Content.NewsEntry.t]
  def recent_news(opts \\ []) do
    case @cms_api.view("/recent-news", opts) do
      {:ok, api_data} -> Enum.map(api_data, &Content.NewsEntry.from_api/1)
      _ -> []
    end
  end

  @spec get_page(String.t, String.t | nil) :: Content.Page.t | nil
  def get_page(path, query_string \\ "") do
    cms_path = if query_string != "" do
      path <> URI.encode_www_form("?#{query_string}")
    else
      path
    end

    case @cms_api.view(cms_path) do
      {:ok, api_data} -> Content.Page.from_api(api_data)
      _ -> nil
    end
  end

  @spec people(Keyword.t) :: [Content.Person.t]
  def people(opts \\ []) do
    case @cms_api.view("/api/people", opts) do
      {:ok, api_data} -> Enum.map(api_data, &Content.Person.from_api/1)
      _ -> []
    end
  end

  @spec person!(integer) :: Content.Person.t | no_return
  def person!(id) do
    case people(id: id) do
      [person] -> person
      _ -> raise Content.NoResultsError
    end
  end

  @spec events(Keyword.t) :: [Content.Event.t]
  def events(opts \\ []) do
    case @cms_api.view("/events", opts) do
      {:ok, api_data} -> Enum.map(api_data, &Content.Event.from_api/1)
      _ -> []
    end
  end

  @spec event!(String.t) :: Content.Event.t | no_return
  def event!(id) do
    case events(id: id) do
      [event] -> event
      _ -> raise Content.NoResultsError
    end
  end

  def event_by(opts) do
    case events(opts) do
      [record] -> record
      [] -> nil
    end
  end

  @spec projects(Keyword.t) :: [Content.Project.t]
  def projects(opts \\ []) do
    case @cms_api.view("/api/projects", opts) do
      {:ok, api_data} -> Enum.map(api_data, &Content.Project.from_api/1)
      _ -> []
    end
  end

  @spec whats_happening() :: [Content.WhatsHappeningItem.t]
  def whats_happening do
    cache [], fn _ ->
      case @cms_api.view("/whats-happening") do
        {:ok, api_data} -> Enum.map(api_data, &Content.WhatsHappeningItem.from_api/1)
        _ -> []
      end
    end
  end

  @spec important_notice() :: Content.ImportantNotice.t | nil
  def important_notice do
    cached_value = cache [], fn _ ->
      case @cms_api.view("/important-notices") do
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
end
