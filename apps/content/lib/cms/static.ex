defmodule Content.CMS.Static do
  @behaviour Content.CMS
  alias Content.NewsEntry

  @news File.read!("priv/news.json")
  @basic_page File.read!("priv/accessibility.json")
  @project_update File.read!("priv/gov-center-project.json")
  @events File.read!("priv/events.json")
  @whats_happening File.read!("priv/whats-happening.json")
  @important_notices File.read!("priv/important-notices.json")
  @all_paragraphs File.read!("priv/accessibility/all-paragraphs.json")
  @landing_page File.read!("priv/denali-national-park.json")

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

  def all_paragraphs_response do
    Poison.Parser.parse!(@all_paragraphs)
  end

  def landing_page_response do
    Poison.Parser.parse!(@landing_page)
  end

  @impl true
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
    news_entry = filter_by(news_response(), "nid", id)
    {:ok, news_entry}
  end
  def view("/news", [migration_id: "multiple-records"]) do
    {:ok, news_response()}
  end
  def view("/news", [migration_id: id]) do
    news = filter_by(news_response(), "field_migration_id", id)
    {:ok, news}
  end
  def view("/news", [page: page]) do
    record = Enum.at(news_response(), page)
    {:ok, [record]}
  end
  def view("/events", [meeting_id: "multiple-records"]) do
    {:ok, events_response()}
  end
  def view("/events", [meeting_id: id]) do
    events = filter_by(events_response(), "field_meeting_id", id)
    {:ok, events}
  end
  def view("/events", opts) do
    events = case Keyword.get(opts, :id) do
      nil -> events_response()
      id -> filter_by(events_response(), "nid", id)
    end

    {:ok, events}
  end
  def view("/whats-happening", _) do
    {:ok, whats_happening_response()}
  end
  def view("/important-notices", _) do
    {:ok, important_notices_response()}
  end
  def view("/accessibility/all-paragraphs", _) do
    {:ok, all_paragraphs_response()}
  end
  def view("/denali-national-park", _) do
    {:ok, landing_page_response()}
  end
  def view(_, _) do
    {:error, "Not able to retrieve response"}
  end

  @impl true
  def post("entity/node", body) do
    if String.contains?(body, "fails-to-create") do
      {:error, %{status_code: 422}}
    else
      body
      |> Poison.Parser.parse!
      |> entity_type()
      |> successful_response()
    end
  end

  @impl true
  def update("node/" <> _id, body) do
    if String.contains?(body, "fails-to-update") do
      {:error, %{status_code: 422}}
    else
      body
      |> Poison.Parser.parse!
      |> entity_type()
      |> successful_response()
    end
  end

  defp successful_response("event") do
    [event | _] = events_response()
    {:ok, event}
  end
  defp successful_response("news_entry") do
    [news_entry | _] = news_response()
    {:ok, news_entry}
  end

  defp entity_type(%{"type" => [%{"target_id" => target_id}]}), do: target_id

  defp filter_by(map, key, value) do
    Enum.filter(map, &(match?(%{^key => [%{"value" => ^value}]}, &1)))
  end
end
