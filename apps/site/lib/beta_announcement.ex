defmodule BetaAnnouncement do

  @doc "Name of the cookie which controls hiding the beta announcement."
  def beta_announcement_cookie, do: "mbta-hide-beta-announcement"

  @doc "Whether or not to show the announcement banner."
  def show_announcement?(conn) do
    Map.get(conn.cookies, beta_announcement_cookie, nil) == nil
  end
end

defmodule BetaAnnouncement.Plug do
  @hide_cookie_param "clear-beta-announcement"
  import Plug.Conn

  def init([]), do: []

  def hide_cookie_param, do: @hide_cookie_param

  def call(%{params: %{@hide_cookie_param => param}} = conn, []) when is_binary(param) do
    conn
    |> put_resp_cookie(
      BetaAnnouncement.beta_announcement_cookie,
      "true",
      max_age: 60 * 60 * 24 * 365 * 100,
      path: "/")
  end
  def call(conn, []) do
    conn
  end
end
