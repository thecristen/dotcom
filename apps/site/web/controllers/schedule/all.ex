defmodule Site.ScheduleController.All do
  use Site.Web, :controller

  def all(conn) do
    conn
    |> render("all.html", 
      grouped_routes: Routes.Repo.all |> Routes.Group.group,
      breadcrumbs: ["Schedules & Maps"]
  )
  end
end
