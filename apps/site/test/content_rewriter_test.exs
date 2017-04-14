defmodule Site.ContentRewriterTest do
  use ExUnit.Case

  import Site.ContentRewriter
  import Mock
  import Phoenix.HTML, only: [raw: 1, safe_to_string: 1]

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
        |> rewrite()

        assert called ResponsiveTables.rewrite_table({"table", [], ["Foo"]})
      end
    end

    test "it handles a plain string" do
      original = raw("I'm a string")
      assert rewrite(original) == original
    end

    test "the different rewriters work well together" do
      rewritten =
        """
        <div>
          Test 1 {{ fa "test" }}, Test 2 {{ fa "test-two" }}
          <table>
            The caption
            <thead>
              <tr>
                <th>Head 1</th>
                <th>Head 2</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>Cell 1 {{ fa "cell" }}</td>
                <td>Cell 2 {{ unknown }}</td>
              </tr>
              <tr>
                <td>Cell 3</td>
                <td>Cell 4</td>
              </tr>
            </tbody>
          </table>
        </div>
        """
        |> raw()
        |> rewrite()

      expected =
        """
        <div>
          Test 1 <i aria-hidden="true" class="fa fa-test "></i>, Test 2 <i aria-hidden="true" class="fa fa-test-two "></i>
          <table class="responsive-table">
            <caption>The caption</caption>
            <thead>
              <tr>
                <th>Head 1</th>
                <th>Head 2</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <th>Head 1</th>
                <td>Cell 1 <i aria-hidden="true" class="fa fa-cell "></i></td>
                <th>Head 2</th>
                <td>Cell 2 {{ unknown }} </td>
              </tr>
              <tr>
                <th>Head 1</th>
                <td>Cell 3</td>
                <th>Head 2</th>
                <td>Cell 4</td>
              </tr>
            </tbody>
          </table>
        </div>
        """

      assert remove_whitespace(safe_to_string(rewritten)) == remove_whitespace(expected)
    end
  end

  def remove_whitespace(str), do: String.replace(str, ~r/[ \n]/, "")
end
