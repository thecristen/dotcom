defmodule Site.ScheduleV2.BusController do
  use Site.Web, :controller

  def show(conn, _params) do
    render(conn, "show.html")
  end
end

