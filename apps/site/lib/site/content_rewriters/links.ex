defmodule Site.ContentRewriters.Links do
  import SiteWeb.ViewHelpers, only: [cms_static_page_path: 2]

  @doc """
  Adds the target=_blank attribute to links that redirect to
  the old site so they open in a new tab.
  """
  @spec add_target_to_redirect(Floki.html_tree) :: Floki.html_tree
  def add_target_to_redirect({"a", attrs, children} = element) do
    case Floki.attribute(element, "href") do
      ["/redirect/" <> _] ->
        case Floki.attribute(element, "target") do
          [] -> {"a", [{"target", "_blank"} | attrs], children}
          _ -> element
        end
       _ -> element
    end
  end

  @doc """
  Adds the ?preview&vid=latest query paramters to relative URLs
  if the current page is in preview mode.
  """
  @spec add_preview_params(Floki.html_tree, Plug.Conn.t) :: Floki.html_tree
  def add_preview_params({"a", attrs, children} = element, conn) do
    case Floki.attribute(element, "href") do
      [path = "/" <> _] ->
        href = cms_static_page_path(conn, path)
        {"a", [{"href", href} | attrs], children}
      _ -> element
    end
  end
end
