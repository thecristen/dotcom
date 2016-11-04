defmodule Site.StaticPageController do
  @moduledoc "Controller for paths which just render a simple static page."
  use Site.Web, :controller

  for page <- Site.StaticPage.static_pages do
    def unquote(page)(conn, _params) do
      render conn, "#{unquote(page)}.html"
    end
  end
end
