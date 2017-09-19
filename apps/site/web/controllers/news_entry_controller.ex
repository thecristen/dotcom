defmodule Site.NewsEntryController do
  use Site.Web, :controller
  alias Site.Pagination
  alias Plug.Conn

  def index(conn, params) do
    page = current_page(params)
    zero_based_current_page = page - 1
    zero_based_next_page = page

    news_entries = Content.Repo.news(page: zero_based_current_page)
    upcoming_news_entries = Content.Repo.news(page: zero_based_next_page)

    conn
    |> assign(:breadcrumbs, index_breadcrumbs())
    |> assign(:news_entries, news_entries)
    |> assign(:upcoming_news_entries, upcoming_news_entries)
    |> assign(:page, page)
    |> assign(:narrow_template, true)
    |> render(:index)
  end

  def show(conn, %{"id" => id}) do
    case Content.Repo.news_entry(id) do
      :not_found -> check_cms_or_404(conn)
      news_entry ->
        recent_news = Content.Repo.recent_news(current_id: news_entry.id)
        conn
        |> assign(:narrow_template, true)
        |> assign(:breadcrumbs, show_breadcrumbs(conn, news_entry))
        |> assign(:news_entry, news_entry)
        |> assign(:recent_news, recent_news)
        |> render(:show)
    end
  end

  defp current_page(params) do
    params
    |> Map.get("page")
    |> Pagination.current_page(1)
  end

  defp index_breadcrumbs do
    [Breadcrumb.build("News")]
  end

  defp show_breadcrumbs(conn, news_entry) do
    [
      Breadcrumb.build("News", news_entry_path(conn, :index)),
      Breadcrumb.build(news_entry.title)
    ]
  end
end
