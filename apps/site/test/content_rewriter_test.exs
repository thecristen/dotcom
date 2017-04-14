defmodule Site.ContentRewriterTest do
  use ExUnit.Case

  import Site.ContentRewriter
  import Mock
  import Phoenix.HTML, only: [raw: 1]

  alias Site.ContentRewriters.ResponsiveTables

  describe "rewrite" do
    test "it returns non-table content unchanged" do
      original = raw("<div><span>Nothing to see here.</span></div>")
      assert rewrite(original) == original
    end

    test "it dispatches to the table rewriter if a table is present" do
      with_mock ResponsiveTables, [rewrite_table: fn(_) -> {"table", [], []} end] do
        "<div><span>Foo</span><table>Foo</table></div>"
        |> raw()
        |> rewrite

        assert called ResponsiveTables.rewrite_table({"table", [], ["Foo"]})
      end
    end

    test "it handles a plain string" do
      original = raw("I'm a string")
      assert rewrite(original) == original
    end
  end
end
