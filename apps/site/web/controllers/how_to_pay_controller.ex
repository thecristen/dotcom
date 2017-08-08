defmodule Site.HowToPayController do
  use Site.Web, :controller

  @how_to_pay_pages ["subway", "commuter_rail", "bus", "ferry", "the_ride"]

  def index(conn, _params) do
    render_view(conn, :subway)
  end

  def show(conn, %{"mode" => mode_string}) when mode_string in @how_to_pay_pages do
    render_view(conn, String.to_existing_atom(mode_string))
  end
  def show(conn, _params) do
    conn
    |> redirect(to: how_to_pay_path(conn, :index))
    |> halt
  end

  defp render_view(conn, mode) do
    render(conn, "how_to_pay.html", [
      mode: mode,
      breadcrumbs: [ {fare_path(conn, :index), "Fares and Passes"}, "How to Pay" ]
    ])
  end
end
