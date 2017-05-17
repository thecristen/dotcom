defmodule Content.CMS.Static do
  @behaviour Content.CMS
  alias Content.NewsEntry

  @news File.read!("priv/news.json")
  @basic_page File.read!("priv/accessibility.json")
  @project_update File.read!("priv/gov-center-project.json")
  @events File.read!("priv/events.json")
  @whats_happening File.read!("priv/whats-happening.json")
  @important_notices File.read!("priv/important-notices.json")

  def news_response do
    Poison.Parser.parse!(@news)
  end

  def basic_page_response do
    Poison.Parser.parse!(@basic_page)
  end

  def project_update_response do
    Poison.Parser.parse!(@project_update)
  end

  def events_response do
    Poison.Parser.parse!(@events)
  end

  def whats_happening_response do
    Poison.Parser.parse!(@whats_happening)
  end

  def important_notices_response do
    Poison.Parser.parse!(@important_notices)
  end

  def view(path, params \\ [])
  def view("/recent-news", [current_id: id]) do
    id = Integer.to_string(id)
    filtered_recent_news = Enum.reject(news_response(), &match?(%{"nid" => [%{"value" => ^id}]}, &1))
    recent_news = Enum.take(filtered_recent_news, NewsEntry.number_of_recent_news_suggestions())

    {:ok, recent_news}
  end
  def view("/recent-news", _) do
    {:ok, Enum.take(news_response(), NewsEntry.number_of_recent_news_suggestions())}
  end
  def view("/accessibility", _) do
    {:ok, basic_page_response()}
  end
  def view("/gov-center-project", _) do
    {:ok, project_update_response()}
  end
  def view("/news", [id: id]) do
    news_entry = Enum.filter(news_response(), &match?(%{"nid" => [%{"value" => ^id}]}, &1))
    {:ok, news_entry}
  end
  def view("/events", [meeting_id: "multiple-records"]) do
    {:ok, events_response()}
  end
  def view("/events", [meeting_id: id]) do
    events =
      events_response()
      |> Enum.filter(
        &(match?(%{"field_meeting_id" => [%{"value" => ^id}]}, &1))
      )

    {:ok, events}
  end
  def view("/events", opts) do
    events = case Keyword.get(opts, :id) do
      nil -> events_response()
      id -> Enum.filter(events_response(), & match?(%{"nid" => [%{"value" => ^id}]}, &1))
    end

    {:ok, events}
  end
  def view("/whats-happening", _) do
    {:ok, whats_happening_response()}
  end
  def view("/important-notices", _) do
    {:ok, important_notices_response()}
  end
  def view(_, _) do
    {:error, "Not able to retrieve response"}
  end
end
