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
    |> render("subway-hub.html")
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
end
