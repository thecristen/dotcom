defmodule Site.ScheduleV2Controller do
  use Site.Web, :controller
  import Site.ControllerHelpers, only: [call_plug: 2]

  alias Routes.Route

  plug Site.Plugs.Route
  plug Site.Plugs.Date
  plug Site.Plugs.DateTime

  @spec show(Plug.Conn.t, map) :: Phoenix.HTML.Safe.t
  def show(%{query_params: %{"tab" => "line"}} = conn, _) do
    conn
    |> assign(:tab, "line")
    |> call_plug(Site.ScheduleV2Controller.Defaults)
    |> call_plug(Site.ScheduleV2Controller.AllStops)
    |> call_plug(Site.ScheduleV2Controller.RouteBreadcrumbs)
    |> line_pipeline([])
    |> call_plug(Site.ScheduleV2Controller.Line)
    |> render("show.html")
  end
  def show(%{query_params: %{"tab" => "trip-view"}} = conn, _) do
    render_trip_view(conn)
  end
  def show(%{assigns: %{route: %Route{type: 2}}} = conn, _) do
    conn
    |> assign(:tab, "timetable")
    |> call_plug(Site.ScheduleV2Controller.Timetable)
    |> render("show.html")
  end
  def show(conn, _) do
    render_trip_view(conn)
  end

  defp render_trip_view(conn) do
    conn
    |> assign(:tab, "trip-view")
    |> call_plug(Site.ScheduleV2Controller.TripView)
    |> render("show.html")
  end

  defp line_pipeline(conn, _) do
    conn
    |> call_plug(Site.ScheduleV2Controller.HoursOfOperation)
    |> call_plug(Site.ScheduleV2Controller.Holidays)
  end
end
