defmodule Site.ContentRewriters.LinksTest do
  use ExUnit.Case, async: true

  import Site.ContentRewriters.Links

  describe "add_target_to_redirect/1" do
    test "adds target=_blank to redirect link without target" do
      assert Floki.attribute(add_target_to_redirect(make_link("/redirect/page_name")), "target") == ["_blank"]
    end
    test "doesn't add target to redirect link with target=_blank" do
      assert Floki.attribute(add_target_to_redirect(make_link("/redirect/page_name", "_blank")), "target") == ["_blank"]
    end
    test "doesn't add target to redirect link with target=_self" do
      assert Floki.attribute(add_target_to_redirect(make_link("/redirect/page_name", "_self")), "target") == ["_self"]
    end
    test "doesn't add target to external link" do
      assert Floki.attribute(add_target_to_redirect(make_link("http://www.google.com")), "target") == []
    end
    test "doesn't add target to internal link" do
      assert Floki.attribute(add_target_to_redirect(make_link("/internal_page")), "target") == []
    end
  end

  @spec make_link(binary, binary | nil) :: Floki.html_tree
  defp make_link(href, target \\ nil)
  defp make_link(href, nil) do
    {"a", [{"href", href}], []}
  end
  defp make_link(href, target) do
    {"a", [{"target", target}, {"href", href}], []}
  end
end
