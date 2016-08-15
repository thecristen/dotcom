defmodule Site.ScheduleController.All do
  use Site.Web, :controller

  import Util

  def all(conn) do
    conn
    |> render("all.html",
      datetime: now,
      grouped_routes: Routes.Repo.all |> Routes.Group.group,
      breadcrumbs: ["Schedules & Maps"]
  )
  end
end
