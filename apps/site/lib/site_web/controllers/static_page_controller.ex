defmodule SiteWeb.StaticPageController do
  @moduledoc "Controller for paths which just render a simple static page."
  use SiteWeb, :controller

  for page <- SiteWeb.StaticPage.static_pages do
    def unquote(page)(conn, _params) do
      render conn, "#{unquote(page)}.html"
    end
  end
end
