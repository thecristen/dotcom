defmodule Site.NewsEntryController do
  use Site.Web, :controller
  alias Site.Pagination

  def index(conn, params) do
    page = current_page(params)
    zero_based_current_page = page - 1
    zero_based_next_page = page

    news_entries = Content.Repo.news(page: zero_based_current_page)
    upcoming_news_entries = Content.Repo.news(page: zero_based_next_page)

    conn
    |> assign(:breadcrumbs, ["News"])
    |> assign(:news_entries, news_entries)
    |> assign(:upcoming_news_entries, upcoming_news_entries)
    |> assign(:page, page)
    |> render(:index)
  end

  def show(conn, %{"id" => id}) do
    news_entry = Content.Repo.news_entry!(id)
    recent_news = Content.Repo.recent_news(current_id: news_entry.id)

    conn
    |> assign(:breadcrumbs, [{news_entry_path(conn, :index), "News"}, news_entry.title])
    |> assign(:news_entry, news_entry)
    |> assign(:recent_news, recent_news)
    |> render(:show)
  end

  defp current_page(params) do
    params
    |> Map.get("page")
    |> Pagination.current_page(1)
  end
end
