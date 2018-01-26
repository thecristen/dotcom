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

  def basic_page_with_breadcrumbs do
    parse_json("on-demand-pilot.json")
  end

  def basic_page_revisions_response do
    parse_json("on-demand-pilot--revisions.json")
  end

  def projects_response do
    parse_json("api/projects.json")
  end

  def project_updates_response do
    parse_json("api/project-updates.json")
  end

  def events_response do
    parse_json("events.json")
  end

  def person_response do
    parse_json("people/joseph-aiello.json")
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

  def route_pdfs_response do
    parse_json("api/route-pdfs.json")
  end

  @impl true
  def view(path, params)
  def view("/recent-news", [current_id: id]) do
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
  def view("/accessibility/the-ride/on-demand-pilot", _) do
    {:ok, basic_page_with_breadcrumbs()}
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
  def view("/news/incorrect-pattern", []) do
    {:ok, Enum.at(news_response(), 1)}
  end
  def view("/news/date/title", []) do
    {:ok, Enum.at(news_response(), 1)}
  end
  def view("/news/2018/news-entry", _) do
    {:ok, List.first(news_response())}
  end
  def view("/news/redirected_url", _) do
    {:error, {:redirect, "/news/date/title"}}
  end
  def view("/events", [meeting_id: "multiple-records"]) do
    {:ok, events_response()}
  end
  def view("/events", [meeting_id: id]) do
    events = filter_by(events_response(), "field_meeting_id", id)
    {:ok, events}
  end
  def view("/events", [id: id]) do
    {:ok, filter_by(events_response(), "nid", id)}
  end
  def view("/events/incorrect-pattern", []) do
    {:ok, Enum.at(events_response(), 1)}
  end
  def view("/events/date/title", []) do
    {:ok, Enum.at(events_response(), 1)}
  end
  def view("/events/redirected_url", _) do
    {:error, {:redirect, "/events/date/title"}}
  end
  def view("/events", _opts) do
    {:ok, events_response()}
  end
  def view("/api/search", [q: "empty", page: 0]) do
    {:ok, search_response_empty()}
  end
  def view("/api/search", _opts) do
    {:ok, search_response()}
  end
  def view("/api/projects", [id: id]) do
    {:ok, filter_by(projects_response(), "nid", id)}
  end
  def view("/api/projects", opts) do
    if Keyword.get(opts, :error) do
      {:error, "Something happened"}
    else
      {:ok, projects_response()}
    end
  end
  def view("/projects/project-name", []) do
    {:ok, Enum.at(projects_response(), 1)}
  end
  def view("/api/project-updates", [id: id]) do
    {:ok, filter_by(project_updates_response(), "nid", id)}
  end
  def view("/api/project-updates", opts) do
    if Keyword.get(opts, :error) do
      {:error, "Something happened"}
    else
      {:ok, project_updates_response()}
    end
  end
  def view("/projects/redirected_project", _) do
    {:error, {:redirect, "/projects/project-name"}}
  end
  def view("/projects/project-name/update/project-progress", []) do
    {:ok, Enum.at(project_updates_response(), 1)}
  end
  def view("/projects/redirected_project/update/not_redirected_update", _) do
    {:ok, Enum.at(project_updates_response(), 1)}
  end
  def view("/projects/project-name/update/redirected-update", _) do
    {:error, {:redirect, "/projects/project-name/update/project-progress"}}
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
  def view("/parking/by-station", _) do
    {:ok, basic_page_with_sidebar_response()}
  end
  def view("/test/redirect", _) do
    {:ok, redirect_response()}
  end
  def view("/test/path%3Fid%3D5", _) do
    {:ok, redirect_with_query_response()}
  end
  def view("/people/joseph-aiello", _) do
    {:ok, person_response()}
  end
  def view("/node/1", _) do
    {:ok, List.first(news_response())}
  end
  def view("/node/17", _) do
    {:ok, List.first(events_response())}
  end
  def view("/node/123", _) do
    {:ok, List.first(project_updates_response())}
  end
  def view("/node/124", _) do
    {:ok, List.last(project_updates_response())}
  end
  def view("/node/2679", _) do
    {:ok, List.first(projects_response())}
  end
  def view("/api/route-pdfs/87", _) do
    {:ok, route_pdfs_response()}
  end
  def view("/api/route-pdfs/error", _) do
    {:error, :invalid_response}
  end
  def view("/api/route-pdfs/" <> _route_id, _) do
    {:ok, []}
  end
  def view("/redirected_url", _) do
    {:error, {:redirect, "/different_url"}}
  end
  def view("/invalid", _) do
    {:error, :invalid_response}
  end
  def view(_, _) do
    {:error, :not_found}
  end

  @impl true
  def preview(node_id)
  def preview(2), do: {:ok, do_preview(Enum.at(news_response(), 1))}
  def preview(5), do: {:ok, do_preview(Enum.at(events_response(), 1))}
  def preview(2678), do: {:ok, do_preview(Enum.at(projects_response(), 1))}
  def preview(124), do: {:ok, do_preview(Enum.at(project_updates_response(), 1))}
  def preview(6), do: {:ok, do_preview(basic_page_response())}
  def preview(2549), do: {:ok, basic_page_revisions_response()}

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

  defp do_preview(%{"title" => [%{"value" => title}]} = response) do
    for vid <- [111, 112, 113] do
      %{response | "vid" => [%{"value" => vid}], "title" => [%{"value" => "#{title} #{vid}"}]}
    end
  end
end
