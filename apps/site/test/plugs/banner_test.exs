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

    test "if there's no alert banner, does no assigns", %{conn: conn} do
      opts = init(banner_fn: &no_banner/0)
      new_conn = call(conn, opts)
      assert new_conn == conn
    end
  end

  defp no_banner, do: nil
end
