defmodule Site.HowToPayController do
  use Site.Web, :controller

  def index(conn, _params) do
    render(conn, "how_to_pay.html", mode: :subway)
  end

  def show(conn, %{"mode" => mode}) do
    render(conn, "how_to_pay.html", mode: String.to_existing_atom(mode))
  end
end
