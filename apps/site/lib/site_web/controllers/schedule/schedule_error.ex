defmodule SiteWeb.ScheduleController.ScheduleError do
  use Plug.Builder

  def call(%{assigns: %{date_in_rating?: true}} = conn, _) do
    conn
  end
  def call(%{assigns: %{date_in_rating?: false}} = conn, _) do
    {:error, [api_error]} =
      Schedules.Repo.by_route_ids(
        [conn.assigns.route.id],
        direction_id: conn.assigns.direction_id,
        date: conn.assigns.date
      )

    assign(conn, :schedule_error, api_error)
  end
end
