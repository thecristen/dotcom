defmodule Site.ScheduleController.Modes.Behaviour do
  @moduledoc "Behaviour for mode hub pages."

  @callback routes() :: [Routes.Route.t]
  @callback delays() :: [Alerts.Alert.t]
  @callback mode_name() :: String.t
  @callback fares() :: String.t
  @callback fare_description() :: String.t
  @callback route_type :: integer
  @callback map_pdf_url :: String.t
  @callback map_image_url :: String.t

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      use Site.Web, :controller

      import Util

      # Returns only those alerts which should be shown on the hub page for `route_type`. This includes
      # all delays for that route type which are current and not ongoing.
      defp mode_delays(route_type) when is_list(route_type) do
        route_type
        |> Enum.flat_map(&mode_delays/1)
        |> Enum.uniq
      end
      defp mode_delays(route_type) do
        Alerts.Repo.all
        |> Alerts.Match.match(%Alerts.InformedEntity{route_type: route_type}, now)
        |> Enum.filter(&(&1.effect_name == "Delay" && &1.lifecycle != "Ongoing"))
      end

      def fares do
        [
          {"CharlieCard", "$2.25"},
          {"CharlieTicket/Cash-on-board", "$2.75"},
          {"LinkPass - unlimited travel on Subway plus Local Bus", "$84.50"}
        ]
      end

      def routes, do: Routes.Repo.by_type(route_type)

      def delays, do: mode_delays(route_type)

      def map_pdf_url do
        "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Rapid%20Transit%20w%20Key%20Bus.pdf"
      end

      def map_image_url, do: static_url(Site.Endpoint, "/images/subway-spider.jpg")

      defoverridable [fares: 0, routes: 0, delays: 0, map_pdf_url: 0, map_image_url: 0]
    end
  end
end

defmodule Site.ScheduleController.Modes.Bus do
  use Site.ScheduleController.Modes.Behaviour

  def route_type, do: 3

  def mode_name, do: "Bus"

  def fare_description do
    "For Inner and Outer Express Bus fares, read the complete Bus Fares page."
  end
end

defmodule Site.ScheduleController.Modes.Subway do
  use Site.ScheduleController.Modes.Behaviour

  def route_type, do: 1

  def routes do
    Routes.Repo.all
    |> Routes.Group.group
    |> Map.get(:subway)
  end

  def delays, do: mode_delays([0, 1])

  def mode_name, do: "Subway"

  def fare_description, do: "Travel anywhere on the Blue, Orange, Red, and Green lines for the same price."
end

defmodule Site.ScheduleController.Modes.Boat do
  use Site.ScheduleController.Modes.Behaviour

  def route_type, do: 4

  def mode_name, do: "Boat"

  def map_image_url, do: static_url(Site.Endpoint, "/images/boat-spider.jpg")

  def map_pdf_url, do: nil

  def fare_description do
    "Fares differ between Commuter Boats & Inner Harbor Ferries."
  end

  def fares do
    [
      {"Inner Harbor Ferry", "$4.00"},
      {"Commuter Boat", "$5.25"},
      {"Hingham or Hull to Logan Airport", "$18.50"},
      {"Zone 1A pass includes travel on Subway, Local Bus, Commuter Zone 1A, & Inner Harbor Ferry", "$84.50"},
      {"Commuter Boat Pass includes travel on Commuter Zones 1-5, Subway, Local Bus, & Inner Harbor Ferry", "$308.00"}
    ]
  end
end

defmodule Site.ScheduleController.Modes.CommuterRail do
  use Site.ScheduleController.Modes.Behaviour

  def route_type, do: 2

  def mode_name, do: "Commuter Rail"

  def map_image_url, do: static_url(Site.Endpoint, "/images/commuter-rail-spider.jpg")

  def map_pdf_url do
    "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Commuter%20Rail%20Map.pdf"
  end

  def fare_description do
    "Commuter Rail fares depend on the distance traveled (zones). Read the information below:"
  end

  def fares do
    [
      {"Zones 1A-10", "$2.10-11.50"},
      {"Monthly Pass, unlimited travel to and from your zone plus travel on all buses, subway, and Inner Harbor Ferry", "$75-362"},
      {"Seniors and Persons with Disabilities", "50%"}
    ]
  end
end

defmodule Site.ScheduleController.Modes do
  use Site.Web, :controller

  def render(conn, mode_strategy) do
    render(conn, "hub.html",
      route_type: mode_strategy.route_type,
      routes: mode_strategy.routes,
      delays: mode_strategy.delays,
      mode_name: mode_strategy.mode_name,
      fares: mode_strategy.fares,
      fare_description: mode_strategy.fare_description,
      map_pdf_url: mode_strategy.map_pdf_url,
      map_image_url: mode_strategy.map_image_url,
      breadcrumbs: [{schedule_path(conn, :index), "Schedules & Maps"}, mode_strategy.mode_name]
    )
  end
end
