defmodule SiteWeb.HowToPayController do
  use SiteWeb, :controller

  @how_to_pay_pages ["subway", "commuter-rail", "bus", "ferry", "the-ride"]

  def index(conn, _params) do
    render_view(conn, :subway)
  end

  def show(conn, %{"mode" => "commuter-rail"}), do: render_view(conn, :commuter_rail)
  def show(conn, %{"mode" => "the-ride"}), do: render_view(conn, :the_ride)
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
      breadcrumbs: breadcrumbs(conn)
    ])
  end

  defp breadcrumbs(conn) do
    [
      Breadcrumb.build("Fares and Passes", fare_path(conn, :index)),
      Breadcrumb.build("How to Pay")
    ]
  end
end
