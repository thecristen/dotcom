defmodule Site.ScheduleV2Controller.Pdf do
  use Site.Web, :controller

  plug Site.Plugs.Route

  def pdf(%Plug.Conn{assigns: %{route: %Routes.Route{} = route} } = conn, _params) do
    case Routes.Pdf.url(route) do
      nil -> conn |> put_status(:not_found) |> render(Site.ErrorView, "404.html", [])
      pdf_url -> conn |> redirect(external: pdf_url)
    end
  end
end
