defmodule Site.ScheduleController do
  use Site.Web, :controller

  alias Site.ScheduleController

  plug Site.Plugs.Route, required: true
  plug Site.Plugs.Date
  plug Site.Plugs.Alerts
  plug ScheduleController.Headsigns
  plug ScheduleController.Defaults
  plug ScheduleController.RouteBreadcrumbs
  plug ScheduleController.Schedules
  plug ScheduleController.Trip
  plug ScheduleController.DateTime
  plug ScheduleController.ViewTemplate
  plug ScheduleController.AllStops
  plug ScheduleController.DirectionNames
  plug ScheduleController.DestinationStops
  plug ScheduleController.Predictions
  plug :disable_cache

  def show(%{query_params: %{"route" => new_route_id}} = conn,
    %{"route" => old_route_id} = params) when new_route_id != old_route_id do
    new_path = schedule_path(conn, :show, new_route_id, Map.delete(params, "route"))
    redirect conn, to: new_path
  end
  def show(conn, params) do
    conn
    |> assign(:date_select, show_datepicker?(params))
    |> assign(:holidays, Holiday.Repo.upcoming_holidays(conn.assigns[:date]))
    |> render("index.html")
  end

  @doc "Disable previews when we're showing predictions"
  def disable_cache(%{assigns: %{predictions: [_|_]}} = conn, []) do
    Turbolinks.Plug.NoCache.call(conn, "no-preview")
  end
  def disable_cache(conn, []) do
    conn
  end

  def show_datepicker?(%{"date_select" => "true"}), do: true
  def show_datepicker?(_), do: false
end
