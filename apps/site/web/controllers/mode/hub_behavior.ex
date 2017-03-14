defmodule Site.Mode.HubBehavior do
  alias Fares.Summary
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
    routes_task = Task.async(mode_strategy, :routes, [])
    fares_task = Task.async(mode_strategy, :fares, [])

    render(conn, "hub.html",
      route_type: mode_strategy.route_type |> Routes.Route.type_atom(),
      routes: Task.await(routes_task),
      mode_name: mode_strategy.mode_name(),
      fares: Task.await(fares_task),
      fare_description: mode_strategy.fare_description(),
      map_pdf_url: MapHelpers.map_pdf_url(mode_strategy.route_type),
      map_image_url: static_url(Site.Endpoint, MapHelpers.map_image_url(mode_strategy.route_type)),
      breadcrumbs: [{mode_path(conn, :index), "Schedules & Maps"}, mode_strategy.mode_name()]
    )
  end
end
