defmodule Site.ServiceNearMeController do
  use Site.Web, :controller
  alias Stops.Stop

  plug Site.Plugs.ServiceNearMe

  @doc """
    Handles GET requests both with and without parameters. Calling with an address parameter (String.t) will assign
    make available to the view:
        @stops_with_routes :: [%{stop: %Stops.Stop{}, routes: [%Route{}]}]
  """
  def index(conn, _params) do
    conn
    |> flash_if_error()
    |> render("index.html", breadcrumbs: ["Service Near Me"])
  end

  @spec flash_if_error(Plug.Conn.t) :: Plug.Conn.t
  def flash_if_error(%Plug.Conn{assigns: %{address: ""}} = conn) do
    put_flash(conn, :info, "No address provided. Please enter a valid address below.")
  end
  def flash_if_error(%Plug.Conn{assigns: %{stops_with_routes: []}} = conn) do
    put_flash(conn, :info, "There doesn't seem to be any stations found near the given address. Please try a different address to continue.")
  end
  def flash_if_error(conn), do: conn
end
