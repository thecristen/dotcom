defmodule Site.Mode.HubBehaviour do
  @moduledoc "Behaviour for mode hub pages."

  @callback routes() :: [Routes.Route.t]
  @callback delays() :: [Alerts.Alert.t]
  @callback mode_name() :: String.t
  @callback fares() :: String.t
  @callback fare_description() :: String.t
  @callback route_type :: integer
  @callback map_pdf_url :: String.t
  @callback map_image_url :: String.t

  use Site.Web, :controller

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      use Site.Web, :controller

      def index(conn, params) do
        unquote(__MODULE__).index(__MODULE__, conn, params)
      end

      def fares do
        [
          {"CharlieCard", "$2.25"},
          {"CharlieTicket/Cash-on-board", "$2.75"},
          {"LinkPass - unlimited travel on Subway plus Local Bus", "$84.50"}
        ]
      end

      def routes, do: Routes.Repo.by_type(route_type)

      def delays, do: unquote(__MODULE__).mode_delays(route_type)

      def map_pdf_url do
        "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Rapid%20Transit%20w%20Key%20Bus.pdf"
      end

      def map_image_url, do: "/images/subway-spider.jpg"

      defoverridable [fares: 0, routes: 0, delays: 0, map_pdf_url: 0, map_image_url: 0]
    end
  end

  def index(mode_strategy, conn, _params) do
    render(conn, "hub.html",
      route_type: mode_strategy.route_type,
      routes: mode_strategy.routes,
      delays: mode_strategy.delays,
      mode_name: mode_strategy.mode_name,
      fares: mode_strategy.fares,
      fare_description: mode_strategy.fare_description,
      map_pdf_url: mode_strategy.map_pdf_url,
      map_image_url: static_url(Site.Endpoint, mode_strategy.map_image_url),
      breadcrumbs: [{mode_path(conn, :index), "Schedules & Maps"}, mode_strategy.mode_name]
    )
  end

  # Returns only those alerts which should be shown on the hub page for `route_type`. This includes
  # all delays for that route type which are current and not ongoing.
  def mode_delays(route_type) when is_list(route_type) do
    route_type
    |> Enum.flat_map(&mode_delays/1)
    |> Enum.uniq
  end
  def mode_delays(route_type) do
    Alerts.Repo.all
    |> Alerts.Match.match(%Alerts.InformedEntity{route_type: route_type}, Util.now)
    |> Enum.filter(&(&1.effect_name == "Delay" && &1.lifecycle != "Ongoing"))
  end
end
