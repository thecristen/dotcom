defmodule SiteWeb.ScheduleController.CMS do
  @moduledoc """
  Fetches teaser content from the CMS.
  """

  @behaviour Plug

  alias Routes.Route
  alias Content.{Repo, Teaser}

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

  @spec get_sidebar_content(Route.t) :: {Teaser.t, [Teaser.t]}
  defp get_sidebar_content(%Route{} = route) do
    featured =
      route.id
      |> Repo.teasers(@featured_opts)
      |> List.first()
      |> set_utm_params(route)

    news =
      route.id
      |> Repo.teasers(type: :news_entry)
      |> Enum.map(&set_utm_params(&1, route))

    {featured, news}
  end

  defp set_utm_params(nil, %Route{}) do
    nil
  end
  defp set_utm_params(%Teaser{} = teaser, %Route{} = route) do
    url = UrlHelpers.build_utm_url(
      teaser,
      source: "schedule",
      type: utm_type(teaser.type),
      term: Route.type_atom(route)
    )
    %{teaser | path: url}
  end

  defp utm_type(:news_entry), do: :news
  defp utm_type(type), do: type
end
