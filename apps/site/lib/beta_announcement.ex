defmodule BetaAnnouncement do

  @doc "Name of the cookie which controls hiding the beta announcement."
  def beta_announcement_cookie, do: "mbta-hide-beta-announcement"

  @doc "Whether or not to show the announcement banner."
  def show_announcement?(conn) do
    Map.get(conn.cookies, beta_announcement_cookie, nil) == nil
  end
end

defmodule BetaAnnouncement.Plug do

  import Plug.Conn

  def init([]), do: []

  def hide_cookie_param, do: "clear-beta-announcement"

  def call(conn, []) do
    if Map.has_key?(conn.params, hide_cookie_param) do
      conn
      |> put_resp_cookie(BetaAnnouncement.beta_announcement_cookie, "true", max_age: 60 * 60 * 24 * 365 * 100)
    else
      conn
    end
  end
end
