defmodule Site.HowToPayController do
  use Site.Web, :controller

  def index(conn, _params) do
    render_view(conn, :subway)
  end

  def show(conn, %{"mode" => mode_string}) do
    render_view(conn, String.to_existing_atom(mode_string))
  end

  defp render_view(conn, mode) do
    render(conn, "how_to_pay.html", [
      mode: mode,
      breadcrumbs: ["Fares and Passes", "How to Pay"]
    ])
  end
end
