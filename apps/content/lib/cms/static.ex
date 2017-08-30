defmodule Content.CMS.Static do
  @behaviour Content.CMS
  alias Content.NewsEntry

  def news_response do
    parse_json("news.json")
  end

  def basic_page_response do
    parse_json("accessibility.json")
  end

  def basic_page_with_sidebar_response do
    parse_json("parking/by-station.json")
  end

  def projects_response do
    parse_json("api/projects.json")
  end

  def project_update_response do
    parse_json("api/project-updates.json")
  end

  def events_response do
    parse_json("events.json")
  end

  def people_response do
    parse_json("api/people.json")
  end

  def search_response do
    parse_json("api/search.json")
  end

  def search_response_empty do
    parse_json("api/search-empty.json")
  end

  def whats_happening_response do
    parse_json("whats-happening.json")
  end

  def important_notices_response do
    parse_json("important-notices.json")
  end

  def all_paragraphs_response do
    parse_json("cms/style-guide/paragraphs.json")
  end

  def landing_page_response do
    parse_json("denali-national-park.json")
  end

  def redirect_response do
    parse_json("redirect.json")
  end

  def redirect_with_query_response do
    parse_json("test/path%3Fid%3D5.json")
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
  def view("/news", [page: _page]) do
    record = List.first(news_response())
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
  def view("/api/search", [q: "empty", page: 0]) do
    {:ok, search_response_empty()}
  end
  def view("/api/search", _opts) do
    {:ok, search_response()}
  end
  def view("/api/people", []) do
    {:ok, people_response()}
  end
  def view("/api/people", [id: id]) do
    {:ok, filter_by(people_response(), "nid", String.to_integer(id))}
  end
  def view("/api/projects", opts) do
    if Keyword.get(opts, :error) do
      {:error, "Something happened"}
    else
      {:ok, projects_response()}
    end
  end
  def view("/whats-happening", _) do
    {:ok, whats_happening_response()}
  end
  def view("/important-notices", _) do
    {:ok, important_notices_response()}
  end
  def view("/cms/style-guide", _) do
    {:ok, all_paragraphs_response()}
  end
  def view("/denali-national-park", _) do
    {:ok, landing_page_response()}
  end
  def view("/test/redirect", _) do
    {:ok, redirect_response()}
  end
  def view("/test/path%3Fid%3D5", _) do
    {:ok, redirect_with_query_response()}
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

  defp parse_json(filename) do
    file_path = [Path.dirname(__ENV__.file), "../../priv/", filename]

    file_path
    |> Path.join()
    |> File.read!()
    |> Poison.Parser.parse!()
  end
end
