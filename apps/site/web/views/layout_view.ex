defmodule Site.LayoutView do
  use Site.Web, :view

  def bold_if_active(conn, path, text) do
    if String.starts_with?(conn.request_path, path) do
      raw "<strong>#{text}</strong>"
    else
      raw text
    end
  end

  def format_header_fare(filters) do
    filters
    |> Fares.Repo.all
    |> List.first
    |> Fares.Format.price
  end

  defp has_styleguide_subpages?(%{params: %{"section" => "content"}}), do: true
  defp has_styleguide_subpages?(%{params: %{"section" => "components"}}), do: true
  defp has_styleguide_subpages?(_), do: false

  @spec styleguide_main_content_class(map) :: String.t
  def styleguide_main_content_class(%{all_subpages: _}), do: " col-md-10"
  def styleguide_main_content_class(_), do: ""

  def get_page_classes(module, template) do
    module_class = module
    |> Module.split
    |> Enum.slice(1..-1)
    |> Enum.join("-")
    |> String.downcase

    template_class = template |> String.replace(".html", "-template")

    "#{module_class} #{template_class}"
  end
end
