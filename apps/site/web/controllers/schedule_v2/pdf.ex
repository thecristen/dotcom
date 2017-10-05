defmodule Site.ScheduleV2Controller.Pdf do
  use Site.Web, :controller

  plug Site.Plugs.Route

  def pdf(%Plug.Conn{assigns: %{route: route}} = conn, %{"date" => date_str}) do
    with {:ok, date} <- Date.from_iso8601(date_str) do
      pdf_from_route_and_date(conn, route, date)
    else
      _ -> render_404(conn)
    end
  end
  def pdf(%Plug.Conn{assigns: %{route: route, date: date}} = conn, _params) do
    pdf_from_route_and_date(conn, route, date)
  end

  @spec pdf_from_route_and_date(Plug.Conn.t, Routes.Route.t, Date.t) :: Plug.Conn.t
  defp pdf_from_route_and_date(conn, route, date) do
    case Routes.Pdf.dated_urls(route, date) do
      [] ->
        render_404(conn)
      [{_date, pdf_url} | _] ->
        redirect(conn, external: static_url(conn, pdf_url))
    end
  end
end
