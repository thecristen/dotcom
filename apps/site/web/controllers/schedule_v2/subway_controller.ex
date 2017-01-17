defmodule Site.ScheduleV2.SubwayController do
  use Site.Web, :controller

  plug Site.Plugs.Date
  plug Site.ScheduleController.Defaults
  plug Site.ScheduleController.Schedules

  def frequency(conn, _params) do
    render(conn, "_frequency.html")
  end
end
