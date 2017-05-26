defmodule Site.ContentRewriter do
  @moduledoc """
  Rewrites the content that comes from the CMS before rendering it to the page.
  """

  alias Site.ContentRewriters.{ResponsiveTables, LiquidObjects}

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
    |> Floki.raw_html
    |> Phoenix.HTML.raw
  end

  defp dispatch_rewrites({"table", _, _} = element) do
    {name, attrs, children} = ResponsiveTables.rewrite_table(element)
    {name, attrs, Site.FlokiHelpers.traverse(children, &dispatch_rewrites/1)}
  end
  defp dispatch_rewrites(content) when is_binary(content) do
    Regex.replace(~r/\{\{(.*)\}\}/U, content, fn(_, obj) ->
      obj
      |> String.strip
      |> LiquidObjects.replace
    end)
  end
  defp dispatch_rewrites(_node) do
    nil
  end
end
