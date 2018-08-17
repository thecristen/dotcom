defmodule SiteWeb.Mode.HubBehavior do
  alias Fares.Summary
  alias Site.MapHelpers
  @moduledoc "Behavior for mode hub pages."

  @callback routes() :: [Routes.Route.t]
  @callback mode_name() :: String.t
  @callback fares() :: [Summary.t]
  @callback fare_description() :: String.t | iodata
  @callback route_type() :: 0..4

  use SiteWeb, :controller

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      use SiteWeb, :controller

      def index(conn, params) do
        unquote(__MODULE__).index(__MODULE__, conn, params)
      end

      def routes, do: Routes.Repo.by_type(route_type())

      defoverridable [routes: 0]
    end
  end

  def index(mode_strategy, conn, _params) do
    mode_routes = mode_strategy.routes()
    conn = redirect_for_filter(conn, mode_strategy.mode_name(), mode_routes)

    if conn.halted() do
      conn
    else
      render_index(conn, mode_strategy, mode_routes)
    end
  end

  defp render_index(conn, mode_strategy, mode_routes) do
    conn
    |> async_assign(:fares, &mode_strategy.fares/0)
    |> async_assign(:all_alerts, fn -> alerts(mode_routes, conn.assigns.date_time) end)
    |> assign(:routes, mode_routes)
    |> assign(:route_type, mode_strategy.route_type |> Routes.Route.type_atom())
    |> assign(:mode_name, mode_strategy.mode_name())
    |> assign(:mode_icon, mode_strategy.mode_icon())
    |> assign(:fare_description, mode_strategy.fare_description())
    |> assign(:map_pdf_url, MapHelpers.map_pdf_url(mode_strategy.route_type))
    |> assign(:map_image_url, MapHelpers.map_image_url(mode_strategy.route_type))
    |> assign(:breadcrumbs, [
        Breadcrumb.build("Schedules & Maps", mode_path(conn, :index)),
        Breadcrumb.build(mode_strategy.mode_name())
       ])
    |> await_assign_all()
    |> render("hub.html")
  end

  defp alerts(mode_routes, now) do
    mode_routes
    |> Enum.map(& &1.id)
    |> Alerts.Repo.by_route_ids(now)
  end

  # Redirect if specific route is requested, Only for bus
  defp redirect_for_filter(%Plug.Conn{query_params: %{"filter" => %{"q" => route_name}}} = conn, "Bus", mode_routes) do
    case Enum.find(mode_routes, &String.downcase(&1.name) == String.downcase(route_name)) do
      nil -> redirect_to_search(conn, %{"query" => route_name, "facets" => "locations,bus,facet-stop"})
      route -> redirect_to_route(conn, route)
    end
  end
  defp redirect_for_filter(conn, _mode, _routes) do
    conn
  end

  defp redirect_to_route(conn, route) do
    conn
    |> redirect(to: line_path(conn, :show, route.id))
    |> halt
  end

  @spec redirect_to_search(Plug.Conn.t(), map) :: Plug.Conn.t()
  defp redirect_to_search(%Plug.Conn{} = conn, %{"query" => _} = query) do
    conn
    |> redirect(to: search_path(conn, :index, query))
    |> halt()
  end
end
