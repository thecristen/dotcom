defmodule Site.ScheduleController do
  use Site.Web, :controller
  use Timex

  def index(conn, %{"route" => route}=params) do
    direction_id = case params["direction_id"] do
                     nil -> 0
                     str -> String.to_integer(str)
                   end

    schedules = Schedules.Repo.all(
      route: route,
      date: Date.today,
      direction_id: direction_id,
      stop_sequence: 1)
    route = schedules
    |> List.first
    |> (fn schedule -> schedule.route end).()

    render(conn, "index.html", schedules: schedules, route: route)
  end
end
