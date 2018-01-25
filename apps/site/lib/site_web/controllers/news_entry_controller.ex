defmodule SiteWeb.NewsEntryController do
  use SiteWeb, :controller
  alias Site.Pagination

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

  def show(conn, %{"alias" => [id]}) do
    entry = id
    |> Content.Helpers.int_or_string_to_int()
    |> Content.Repo.news_entry()
    do_show(conn, entry)
  end
  def show(conn, _), do: do_show(conn, Content.Repo.get_page(conn.request_path, conn.query_params))

  defp do_show(conn, maybe_news) do
    case maybe_news do
      :not_found -> check_cms_or_404(conn)
      news_entry -> show_news_entry(conn, news_entry)
    end
  end

  @spec show_news_entry(Plug.Conn.t, Content.NewsEntry.t) :: Plug.Conn.t
  def show_news_entry(conn, %Content.NewsEntry{} = news_entry) do
    recent_news = Content.Repo.recent_news(current_id: news_entry.id)
    conn
    |> assign(:narrow_template, true)
    |> assign(:breadcrumbs, show_breadcrumbs(conn, news_entry))
    |> assign(:news_entry, news_entry)
    |> assign(:recent_news, recent_news)
    |> render("show.html")
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
