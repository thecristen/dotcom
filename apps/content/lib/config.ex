defmodule Content.Config do
  @doc "Returns a full URL for the given path. Raises if the root URL is not defined."
  @spec url(String.t) :: String.t | no_return
  def url(path) when is_binary(path) do
    case root() do
      nil -> raise "Drupal root is not configured"
      base_url -> base_url |> URI.merge(path) |> URI.to_string
    end
  end

  @doc "Returns the path prefix for static content."
  @spec static_path() :: String.t
  def static_path do
    Util.config(:content, :drupal, :static_path)
  end

  @doc "Returns the host/domain of Drupal."
  @spec root() :: String.t | nil
  def root do
    Util.config(:content, :drupal, :root)
  end
end
