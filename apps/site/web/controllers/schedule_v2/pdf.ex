defmodule Site.ScheduleV2Controller.Pdf do
  use Site.Web, :controller

  plug Site.Plugs.Route

  def pdf(%Plug.Conn{assigns: %{route: route}} = conn, %{"date" => date_str}) do
    with {:ok, date} <- Date.from_iso8601(date_str),
         [{_date, pdf_url} | _] <- Routes.Pdf.dated_urls(route, date) do
      redirect(conn, external: pdf_url)
    else
      _ -> not_found(conn)
    end
  end
  def pdf(%Plug.Conn{assigns: %{route: route}} = conn, _params) do
    case Routes.Pdf.url(route) do
      nil -> not_found(conn)
      pdf_url -> conn |> redirect(external: pdf_url)
    end
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
  end
end
