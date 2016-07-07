defmodule Site.ScheduleController.Modes do
  @moduledoc "Schedules hub for each mode of transport."

  use Site.Web, :controller

  import Site.ScheduleController.Helpers

  def subway(conn) do
    routes = [0, 1]
    |> Routes.Repo.by_type
    |> Routes.Group.group
    |> Map.get(:subway)

    conn
    |> assign(:routes, routes)
    |> assign(:delays, mode_delays([0, 1]))
    |> assign(:route_type, 1)
    |> assign(:mode_name, "subway")
    |> assign(:fare_description, "Travel anywhere on the Blue, Orange, Red, and Green lines for the same price.")
    |> assign(:fares, fares("subway"))
    |> render("hub.html")
  end

  def bus(conn) do
    conn
    |> assign(:routes, Routes.Repo.by_type(3))
    |> assign(:delays, mode_delays(3))
    |> assign(:route_type, 3)
    |> assign(:mode_name, "bus")
    |> assign(:fare_description, "For Inner and Outer Express Bus fares, read the complete Bus Fares page.")
    |> assign(:fares, fares("bus"))
    |> render("hub.html")
  end

  # Returns only those alerts which should be shown on the hub page for `route_type`. This includes
  # all delays for that route type which are current and not ongoing.
  defp mode_delays(route_type) when is_list(route_type) do
    route_type
    |> Enum.flat_map(&mode_delays/1)
  end
  defp mode_delays(route_type) do
    Alerts.Repo.all
    |> Alerts.Match.match(%Alerts.InformedEntity{route_type: route_type}, Timex.DateTime.now)
    |> Enum.filter(&(&1.effect_name == "Delay" && &1.lifecycle != "Ongoing"))
  end

  defp fares(mode) when mode in ["subway", "bus"] do
    [
      {"Passes/Tickets", "Fare"},
      {"CharlieCard", "$2.25"},
      {"CharlieTicket/Cash-on-board", "$2.75"},
      {"LinkPass - unlimited travel on Subway plus Local Bus", "$84.50"}
    ]
  end
end
