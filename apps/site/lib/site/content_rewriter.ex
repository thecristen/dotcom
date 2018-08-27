defmodule Site.ContentRewriter do
  @moduledoc """
  Rewrites the content that comes from the CMS before rendering it to the page.
  """

  alias Site.ContentRewriters.{ResponsiveTables, LiquidObjects, Links, EmbeddedMedia}
  alias Site.FlokiHelpers

  @doc """
  The main entry point for the various transformations we apply to CMS content
  before rendering to the page. The content is parsed by Floki and then traversed
  with a dispatch function that will identify nodes to be rewritten and pass
  them to the modules and functions responsible. See the Site.FlokiHelpers.traverse
  docs for more information about how the visitor function should work to
  traverse and manipulate the tree.
  """
  @spec rewrite(Phoenix.HTML.safe | String.t, Plug.Conn.t) :: Phoenix.HTML.safe
  def rewrite({:safe, content}, conn) do
    content
    |> Floki.parse
    |> FlokiHelpers.traverse(&dispatch_rewrites(&1, conn))
    |> render
    |> Phoenix.HTML.raw
  end
  def rewrite(content, conn) when is_binary(content) do
    dispatch_rewrites(content, conn)
  end

  # necessary since foo |> Floki.parse |> Floki.raw_html blows up
  # if there are no HTML tags in foo.
  defp render(content) when is_binary(content), do: content
  defp render(content), do: Floki.raw_html(content)

  @spec dispatch_rewrites(Floki.html_tree | binary, Plug.Conn.t) :: Floki.html_tree | binary | nil
  defp dispatch_rewrites({"table", _, _} = element, conn) do
    table = element
    |> ResponsiveTables.rewrite_table()
    |> rewrite_children(conn)

    {"figure", [{"class", "c-media c-media--type-table"}], [
      {"div", [{"class", "c-media__content"}], [
        table
      ]}
    ]}
  end
  defp dispatch_rewrites({"p", _, _} = element, conn) do
    element
    |> Floki.find("a.btn")
    |> case do
      [buttons] -> {"div", [{"class", "c-inline-buttons"}], buttons}
      _ -> element end
    |> rewrite_children(conn)
  end
  defp dispatch_rewrites({"a", _, _} = element, conn) do
    element
    |> Links.add_target_to_redirect()
    |> Links.add_preview_params(conn)
    |> rewrite_children(conn)
  end
  defp dispatch_rewrites({"img", _, _} = element, conn) do
    element
    |> FlokiHelpers.remove_style_attrs()
    |> FlokiHelpers.add_class("img-fluid")
    |> rewrite_children(conn)
  end
  defp dispatch_rewrites({_, [{"class", "iframe-container"}], [{"iframe", _, _}]} = element, _conn) do
    element
  end
  defp dispatch_rewrites({_, [{"class", "embedded-entity" <> _}], _children} = element, conn) do
    element
    |> EmbeddedMedia.parse
    |> EmbeddedMedia.build
    |> rewrite_children(conn)
  end
  defp dispatch_rewrites({"iframe", _, _} = element, _conn) do
    iframe = FlokiHelpers.remove_style_attrs(element)
    src = iframe |> Floki.attribute("src") |> List.to_string()

    if EmbeddedMedia.media_iframe?(src) do
      EmbeddedMedia.iframe(iframe)
    else
      {"div", [{"class", "iframe-container"}], FlokiHelpers.add_class(iframe, "iframe")}
    end
  end
  defp dispatch_rewrites(content, _conn) when is_binary(content) do
    Regex.replace(~r/\{\{(.*)\}\}/U, content, fn(_, obj) ->
      obj
      |> String.trim
      |> LiquidObjects.replace
    end)
  end
  defp dispatch_rewrites(_node, _conn) do
    nil
  end

  defp rewrite_children({name, attrs, children}, conn) do
    {name, attrs, FlokiHelpers.traverse(children, &dispatch_rewrites(&1, conn))}
  end
end
