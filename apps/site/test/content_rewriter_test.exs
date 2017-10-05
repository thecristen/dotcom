defmodule Site.ContentRewriterTest do
  use ExUnit.Case

  import Site.ContentRewriter
  import Mock
  import Site.ContentView, only: [svg_icon_with_circle: 1]
  import Phoenix.HTML, only: [raw: 1, safe_to_string: 1]

  alias Site.Components.Icons.SvgIconWithCircle
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
                <td>Cell 3 {{ mbta-circle-icon "bus" }}</td>
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
                <td>Cell 3 #{svg_bus()}</td>
                <th>Head 2</th>
                <td>Cell 4</td>
              </tr>
            </tbody>
          </table>
        </div>
        """

      assert remove_whitespace(safe_to_string(rewritten)) == remove_whitespace(expected)
    end

    test "strips dimension attributes from images" do
      assert ~s(<img src="/image.png" alt="an image" width="600" height="400"/>)
             |> raw()
             |> rewrite() == {:safe, ~s(<img class="img-fluid" src="/image.png" alt="an image"/>)}
    end

    test "adds img-fluid to images that don't already have a class" do
      assert ~s(<img src="/image.png" alt="an image" />)
             |> raw()
             |> rewrite() == {:safe, ~s(<img class="img-fluid" src="/image.png" alt="an image"/>)}
    end

    test "adds img-fluid to images that do already have a class" do
      assert ~s(<img src="/image.png" alt="an image" class="existing-class" />)
             |> raw()
             |> rewrite() == {:safe, ~s(<img class="existing-class img-fluid" src="/image.png" alt="an image"/>)}
    end

  end

  defp remove_whitespace(str), do: String.replace(str, ~r/[ \n]/, "")

  defp svg_bus do
    %SvgIconWithCircle{icon: :bus}
    |> svg_icon_with_circle
    |> safe_to_string
  end
end
