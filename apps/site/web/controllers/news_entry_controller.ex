defmodule Site.NewsEntryController do
  use Site.Web, :controller

  def show(conn, %{"id" => id}) do
    news_entry = Content.Repo.news_entry!(id)
    recent_news = Content.Repo.recent_news(current_id: news_entry.id)

    conn
    |> assign(:news_entry, news_entry)
    |> assign(:recent_news, recent_news)
    |> render(:show)
  end
end
