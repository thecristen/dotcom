defmodule SiteWeb.Mode.HubBehavior do
  alias Content.Teaser
  alias Fares.Summary

  @moduledoc "Behavior for mode hub pages."

  @callback routes() :: [Routes.Route.t()]
  @callback mode_name() :: String.t()
  @callback fares() :: [Summary.t()]
  @callback fare_description() :: String.t() | iodata
  @callback route_type() :: 0..4

  use SiteWeb, :controller

  defmacro __using__(opts) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      use SiteWeb, :controller

      plug(SiteWeb.Plugs.RecentlyVisited)

      def index(conn, params) do
        unquote(__MODULE__).index(__MODULE__, conn, Map.merge(params, Map.new(unquote(opts))))
      end

      def routes, do: Routes.Repo.by_type(route_type())

      defoverridable routes: 0
    end
  end

  def index(mode_strategy, conn, params) do
    mode_routes = mode_strategy.routes()

    render_index(conn, mode_strategy, mode_routes, params)
  end

  defp render_index(conn, mode_strategy, mode_routes, params) do
    conn
    |> filter_recently_visited(mode_strategy.route_type)
    |> async_assign(:fares, &mode_strategy.fares/0)
    |> async_assign(:alerts, fn -> alerts(mode_routes, conn.assigns.date_time) end)
    |> assign(:green_routes, green_routes())
    |> assign(:routes, mode_routes)
    |> assign(:route_type, mode_strategy.route_type |> Routes.Route.type_atom())
    |> assign(:mode_name, mode_strategy.mode_name())
    |> assign(:mode_icon, mode_strategy.mode_icon())
    |> assign(:fare_description, mode_strategy.fare_description())
    |> assign(:maps, mode_strategy.mode_icon() |> maps())
    |> assign(:guides, mode_strategy.mode_name() |> guides())
    |> assign(:news, mode_strategy.mode_name() |> news())
    |> assign(:breadcrumbs, [
      Breadcrumb.build("Schedules & Maps", mode_path(conn, :index)),
      Breadcrumb.build(mode_strategy.mode_name())
    ])
    |> meta_description(params)
    |> await_assign_all()
    |> render("hub.html")
  end

  defp filter_recently_visited(
         %{assigns: %{recently_visited: recently_visited}} = conn,
         route_type
       )
       when route_type in [2, 3] do
    filtered = Enum.filter(recently_visited, &(&1.type == route_type))
    assign(conn, :recently_visited, filtered)
  end

  defp filter_recently_visited(conn, _route_type) do
    assign(conn, :recently_visited, [])
  end

  defp alerts(mode_routes, now) do
    mode_routes
    |> Enum.map(& &1.id)
    |> Alerts.Repo.by_route_ids(now)
  end

  defp meta_description(conn, %{meta_description: meta_description}) do
    conn
    |> assign(:meta_description, meta_description)
  end

  defp meta_description(conn, _), do: conn

  def maps(:commuter_rail), do: [:commuter_rail, :commuter_rail_zones]
  def maps(type), do: [type]

  @spec guides(String.t()) :: [Teaser.t()]
  defp guides(mode) do
    Content.Repo.teasers(topic: "guides", sidebar: 1, mode: mode_to_param(mode))
  end

  @spec mode_to_param(String.t()) :: String.t()
  defp mode_to_param(mode) do
    mode
    |> String.downcase()
    |> String.replace(" ", "-")
  end

  @spec news(String.t()) :: [Teaser.t()]
  defp news(mode) do
    mode
    |> mode_to_param()
    |> do_news()
  end

  @spec do_news(String.t()) :: [Teaser.t()]
  defp do_news(mode) do
    [mode: mode, type: :news_entry, sidebar: 1]
    |> Content.Repo.teasers()
    |> Enum.map(&news_url(&1, mode))
  end

  @spec news_url(Teaser.t(), String.t()) :: Teaser.t()
  defp news_url(%Teaser{} = news, mode) do
    url = UrlHelpers.build_utm_url(news, source: "hub", term: mode, type: "sidebar")
    %{news | path: url}
  end
end
