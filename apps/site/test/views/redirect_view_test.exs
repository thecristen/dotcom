defmodule Site.RedirectViewTest do
  use Site.ConnCase, async: true

  test "Does not alter subdomain path" do
    assert Site.RedirectView.redirect_url(true, "subdomain.mbta.com/Public") == "subdomain.mbta.com/Public"
  end

  describe "URL is not a subdomain" do
    test "given url is appended to old site" do
      assert Site.RedirectView.redirect_url(false, "about_the_mbta") == "http://www.mbta.com/about_the_mbta"
    end
  end
end
