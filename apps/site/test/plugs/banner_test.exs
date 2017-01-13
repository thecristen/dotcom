defmodule Site.Plugs.BannerTest do
  use Site.ConnCase, async: true

  import Site.Plugs.Banner
  alias Alerts.Banner

  describe "call/2" do
    test "if there's an alert banner, assigns it along with the banner class/template", %{conn: conn} do
      opts = init(banner_fn: fn -> %Banner{} end)
      conn = call(conn, opts)
      assert conn.assigns.alert_banner == %Banner{}
      assert conn.assigns.banner_class == "alert-announcement-container"
      assert conn.assigns.banner_template == "_alert_announcement.html"
    end

    test "if there's no alert banner and we should show the beta message, assigns that template", %{conn: conn} do
      # also asserts that show_announcement_fn? is called with the conn value
      opts = init(banner_fn: &no_banner/0, show_announcement_fn?: (fn ^conn -> true end))
      conn = call(conn, opts)
      assert conn.assigns.banner_template == "_beta_announcement.html"
    end

    test "if there's no alert banner and no beta announcment, does no assigns", %{conn: conn} do
      opts = init(banner_fn: &no_banner/0, show_announcement_fn?: &no_show?/1)
      new_conn = call(conn, opts)
      assert new_conn == conn
    end
  end

  defp no_banner(), do: nil
  defp no_show?(_), do: false
end
