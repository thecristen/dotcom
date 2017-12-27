defmodule SiteWeb.ResourceLinkHelpers do
  alias  SiteWeb.Router.Helpers

  @doc "Wrapper for path helper functions that return non-encoded URL"
  @spec show_path(:event | :news | :project, String.t) :: String.t
  def show_path(route, path_alias) do
    path_fn = path_fn(route)
    URI.decode(path_fn.(SiteWeb.Endpoint, :show, path_alias))
  end

  defp path_fn(:event), do: &Helpers.event_path/3
  defp path_fn(:news), do: &Helpers.news_entry_path/3
  defp path_fn(:project), do: &Helpers.project_path/3
end
