defmodule Site.ScheduleV2Controller.Pdf do
  use Site.Web, :controller

  plug Site.Plugs.Route

  def pdf(%Plug.Conn{assigns: %{route: route}} = conn, %{"date" => date_str}) do
    with {:ok, date} <- Date.from_iso8601(date_str),
         [{_date, pdf_url} | _] <- Routes.Pdf.dated_urls(route, date) do
      redirect(conn, external: static_url(conn, pdf_url))
    else
      _ -> render_404(conn)
    end
  end
  def pdf(%Plug.Conn{assigns: %{route: route}} = conn, _params) do
    case Routes.Pdf.url(route) do
      nil -> render_404(conn)
      pdf_url -> conn |> redirect(external: static_url(conn, pdf_url))
    end
  end
end
