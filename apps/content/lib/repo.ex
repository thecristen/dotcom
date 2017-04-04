defmodule Content.Repo do
  @moduledoc """

  Interface for the content CMS. Returns a variety of content
  related structs, like %Content.Event{} or %Content.BasicPage{}

  """

  use RepoCache, ttl: :timer.minutes(1)

  @cms_api Application.get_env(:content, :cms_api)

  @spec recent_news() :: [Content.NewsEntry.t]
  def recent_news do
    case @cms_api.view("/recent-news") do
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

  @spec important_notices() :: [Content.ImportantNotice.t]
  def important_notices do
    cache [], fn _ ->
      case @cms_api.view("/important-notices") do
        {:ok, api_data} -> Enum.map(api_data, &Content.ImportantNotice.from_api/1)
        _ -> []
      end
    end
  end
end
