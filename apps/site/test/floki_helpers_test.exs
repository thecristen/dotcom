defmodule Site.FlokiHelpersTest do
  use ExUnit.Case, async: true

  import Site.FlokiHelpers

  setup do
    html = Floki.parse(
      """
        <div><span class="highlight">Hello, this is some text</span></div>
        <div>
          <ul>
            <li>One</li>
            <li>Two</li>
          </ul>
        </div>
      """
    )

    %{html: html}
  end

  describe "traverse" do
    test "if function returns nil it returns all nodes unchanged", %{html: html} do
      expected = traverse(html, fn _ -> nil end)
      assert expected == [
        {"div", [], [{"span", [{"class", "highlight"}], ["Hello, this is some text"]}]},
        {"div", [], [
          {"ul", [], [
            {"li", [], ["One"]},
            {"li", [], ["Two"]},
          ]}
        ]}
      ]
    end

    test "visitor function can replace text", %{html: html} do
      expected = traverse(html, fn node ->
        case node do
          "One" -> "Neo"
          _ -> nil
        end
      end)

      assert expected == [
        {"div", [], [{"span", [{"class", "highlight"}], ["Hello, this is some text"]}]},
        {"div", [], [
          {"ul", [], [
            {"li", [], ["Neo"]},
            {"li", [], ["Two"]},
          ]}
        ]}
      ]
    end

    test "visitor function can replace subtree", %{html: html} do
      expected = traverse(html, fn node ->
        case node do
          {"ul", _, _} -> {"div", [], ["Not anymore!"]}
          _ -> nil
        end
      end)

      assert expected == [
        {"div", [], [{"span", [{"class", "highlight"}], ["Hello, this is some text"]}]},
        {"div", [], [
          {"div", [], ["Not anymore!"]}
        ]}
      ]
    end
  end
end
