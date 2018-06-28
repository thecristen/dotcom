defmodule SiteWeb.StaticPageController do
  @moduledoc "Controller for paths which just render a simple static page."
  use SiteWeb, :controller

  for page <- SiteWeb.StaticPage.static_pages do
    def unquote(page)(conn, _params) do
      conn
      |> assign(:breadcrumbs, build_breadcrumb(unquote(page)))
      |> render("#{unquote(page)}.html")
    end
  end

  @spec build_breadcrumb(atom) :: [Breadcrumb.t]
  def build_breadcrumb(page) do
    page
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
    |> Breadcrumb.build()
    |> List.wrap()
  end
end
