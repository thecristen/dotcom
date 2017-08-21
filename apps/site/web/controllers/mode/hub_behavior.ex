defmodule Site.Mode.HubBehavior do
  alias Fares.Summary
  alias Site.MapHelpers
  @moduledoc "Behavior for mode hub pages."

  @callback routes() :: [Routes.Route.t]
  @callback mode_name() :: String.t
  @callback fares() :: [Summary.t]
  @callback fare_description() :: String.t | iodata
  @callback route_type() :: 0..4

  use Site.Web, :controller

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      use Site.Web, :controller

      def index(conn, params) do
        unquote(__MODULE__).index(__MODULE__, conn, params)
      end

      def routes, do: Routes.Repo.by_type(route_type())

      defoverridable [routes: 0]
    end
  end

  def index(mode_strategy, conn, _params) do
    routes = mode_strategy.routes()
    conn
    |> async_assign(:fares, &mode_strategy.fares/0)
    |> async_assign(:all_alerts, fn -> alerts(routes, conn.assigns.date_time) end)
    |> assign(:routes, routes)
    |> assign(:route_type, mode_strategy.route_type |> Routes.Route.type_atom())
    |> assign(:mode_name, mode_strategy.mode_name())
    |> assign(:fare_description, mode_strategy.fare_description())
    |> assign(:map_pdf_url, MapHelpers.map_pdf_url(mode_strategy.route_type))
    |> assign(:map_image_url, static_url(Site.Endpoint, MapHelpers.map_image_url(mode_strategy.route_type)))
    |> assign(:breadcrumbs, [
        Breadcrumb.build("Schedules & Maps", mode_path(conn, :index)),
        Breadcrumb.build(mode_strategy.mode_name())
       ])
    |> await_assign_all()
    |> render("hub.html")
  end

  defp alerts(routes, now) do
    routes
    |> Enum.map(& &1.id)
    |> Alerts.Repo.by_route_ids(now)
  end
end
