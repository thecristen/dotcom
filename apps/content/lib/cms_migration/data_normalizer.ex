defmodule Content.CmsMigration.DataNormalizer do
  @spec update_relative_links(String.t, String.t, String.t) :: String.t
  def update_relative_links(text, path, host) do
    file_path = build_path(host, path)
    Regex.replace(~r/href=\"\/#{path}/i, text, "href=\"#{file_path}")
  end

  @spec update_relative_image_paths(String.t, String.t, String.t) :: String.t
  def update_relative_image_paths(text, path, host) do
    image_path = build_path(host, path)
    Regex.replace(~r/src=\"\/#{path}/i, text, "src=\"#{image_path}")
  end

  defp build_path(host, path) do
    host
    |> URI.merge(path)
    |> to_string
  end

  @spec remove_style_information(String.t) :: String.t
  def remove_style_information(string) do
    string
    |> remove_style_attrs
    |> remove_style_tags
  end

  defp remove_style_attrs(string) do
    Regex.replace(~r/\sstyle=".*"/U, string, "")
  end

  defp remove_style_tags(string) do
    Regex.replace(~r/<style.*<\/style>/U, string, "")
  end
end
