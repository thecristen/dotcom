defmodule Site.ScheduleV2Controller.Pdf do
  @moduledoc """
  For getting all the pdfs associated with a route from the CMS.
  The pdf action redirects to the most up-to-date pdf.
  """

  use Site.Web, :controller

  plug Site.ScheduleV2Controller.RoutePdfs

  def pdf(%Plug.Conn{assigns: %{route_pdfs: pdfs}} = conn, _params) do
    case pdfs do
      [] ->
        render_404(conn)
      [%Content.RoutePdf{path: path} | _] ->
        redirect(conn, external: static_url(Site.Endpoint, path))
     end
  end
end
