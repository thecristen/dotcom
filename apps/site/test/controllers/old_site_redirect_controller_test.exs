defmodule Site.OldSiteRedirectControllerTest do
  use Site.ConnCase, async: true

  describe "/uploadedfiles" do
    test "can return a file with spaces in the URL", %{conn: conn} do
      conn = head conn, "/uploadedfiles/Documents/Schedules_and_Maps/Rapid Transit w Key Bus.pdf"
      assert conn.status == 200
    end
  end
end
