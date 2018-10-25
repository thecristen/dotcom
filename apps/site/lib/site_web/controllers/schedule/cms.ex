defmodule SiteWeb.ScheduleController.CMS do
  @moduledoc """
  Fetches teaser content from the CMS.
  """

  @behaviour Plug

  alias Routes.Route

  import Plug.Conn, only: [assign: 3]

  @impl Plug
  def init([]), do: []

  @impl Plug
  def call(conn, _) do
    {featured, news} = get_sidebar_content(conn.assigns.route)

    conn
    |> assign(:featured_content, featured)
    |> assign(:news, news)
  end

  @featured_opts [
    type: :news_entry,
    type_op: "not in",
    items_per_page: 1
  ]

  @spec get_sidebar_content(Route.t) :: {[Content.Teaser.t], [Content.Teaser.t]}
  defp get_sidebar_content(%Route{id: id}) do
    featured =
      id
      |> Content.Repo.teasers(@featured_opts)
      |> List.first()

    news = Content.Repo.teasers(id, type: :news_entry)

    {featured, news}
  end
end
