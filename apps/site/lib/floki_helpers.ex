defmodule Site.FlokiHelpers do
  @moduledoc """
  Helpers for working with Floki and the parsed HTML it returns.
  """

  @doc """
  traverse is the main way of manipulating the parse tree. It recursively traverses
  the tree, passing each node to the provided visit_fn visitor function.

  If the visitor function returns nil, traverse continues to descend through the tree. If the
  function returns a Floki.html_tree or string, traverse replaces the node with that result and stops
  recursively descending down that branch.

  The visit_fn must handle a (non-list) Floki.html_tree node and a binary string.
  """
  @spec traverse(Floki.html_tree, (Floki.html_tree | binary -> Floki.html_tree | binary | nil)) :: Floki.html_tree
  def traverse(str, visit_fn) when is_binary(str) do
    visit_fn.(str) || str
  end
  def traverse(html_list, visit_fn) when is_list(html_list) do
    Enum.map(html_list, fn html -> traverse(html, visit_fn) end)
  end
  def traverse({element, attrs, children} = html, visit_fn) do
    visit_fn.(html) || {element, attrs, traverse(children, visit_fn)}
  end
end
