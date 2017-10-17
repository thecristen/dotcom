defmodule Site.ScheduleV2Controller.Pdf do
  use Site.Web, :controller

  def pdf(%Plug.Conn{assigns: %{date: date}} = conn, %{"route" => route_id}) do
    case Routes.Pdf.dated_urls(route_id, date) do
      [] ->
        render_404(conn)
      [{_date, pdf_url} | _] ->
        redirect(conn, external: static_url(conn, pdf_url))
    end
  end
end
