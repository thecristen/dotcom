defmodule Site.ContentRewriter do
  @moduledoc """
  Rewrites the content that comes from the CMS before rendering it to the page.
  """

  @doc """
  The main entry point for the various transformations we apply to CMS content
  before rendering to the page. The content is parsed by Floki and then traversed
  with a dispatch function that will identify nodes to be rewritten and pass
  them to the modules and functions responsible. See the Site.FlokiHelpers.traverse
  docs for more information about how the visitor function should work to
  traverse and manipulate the tree.
  """
  @spec rewrite(Phoenix.HTML.safe) :: Phoenix.HTML.safe
  def rewrite({:safe, content}) do
    content
    |> Floki.parse
    |> Site.FlokiHelpers.traverse(&dispatch_rewrites/1)
    |> render
    |> Phoenix.HTML.raw
  end

  # necessary since foo |> Floki.parse |> Floki.raw_html blows up
  # if there are no HTML tags in foo.
  defp render(content) when is_binary(content), do: content
  defp render(content), do: Floki.raw_html(content)

  defp dispatch_rewrites({"table", _attrs, _children} = element) do
    Site.ContentRewriters.ResponsiveTables.rewrite_table(element)
  end
  defp dispatch_rewrites(_node) do
    nil
  end
end
