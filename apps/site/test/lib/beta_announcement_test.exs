defmodule Site.BetaAnnouncementTest do
  use Site.ConnCase, async: true

  import BetaAnnouncement

  test "show_announcement checks for the presence of the beta announcement cookie", %{conn: conn} do
    assert show_announcement?(conn)

    conn = conn
    |> put_req_cookie(beta_announcement_cookie, "true")
    |> Plug.Conn.fetch_cookies

    refute show_announcement?(conn)
  end
end
