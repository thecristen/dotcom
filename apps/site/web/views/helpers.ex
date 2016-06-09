defmodule Site.ViewHelpers do
  import Site.Router.Helpers

  def redirect_path(conn, path) do
    redirect_path(conn, :show, path)
  end

  def google_api_key do
    env(:google_api_key)
  end

  def font_awesome_id do
    env(:font_awesome_id)
  end

  defp env(key) do
    Application.get_env(:site, __MODULE__)[key]
  end
end
