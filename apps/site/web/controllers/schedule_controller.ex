defmodule Site.ScheduleController do
  use Site.Web, :controller

  def index(conn, _params) do
    render(conn, "index.html", schedules: [])
  end
end
