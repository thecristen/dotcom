defmodule Content.Repo do
  @moduledoc """

  Interface for the content CMS. Returns a variety of content
  related structs, like %Content.Event{} or %Content.BasicPage{}

  """

  use RepoCache, ttl: :timer.minutes(1)

  @cms_api Application.get_env(:content, :cms_api)

  @spec news_entry!(integer) :: Content.NewsEntry.t | no_return
  def news_entry!(id) do
    case @cms_api.view("/news", [id: id]) do
      {:ok, [news_entry]} -> Content.NewsEntry.from_api(news_entry)
      _ -> raise Content.NoResultsError
    end
  end

  @spec recent_news(Keyword.t) :: [Content.NewsEntry.t]
  def recent_news(opts \\ []) do
    case @cms_api.view("/recent-news", opts) do
      {:ok, api_data} -> Enum.map(api_data, &Content.NewsEntry.from_api/1)
      _ -> []
    end
  end

  @spec get_page(String.t) :: Content.BasicPage.t | Content.NewsEntry.t | Content.ProjectUpdate.t | nil
  def get_page(path) do
    case @cms_api.view(path) do
      {:ok, api_data} -> Content.Page.from_api(api_data)
      _ -> nil
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
end
