defmodule Site.ContentRewriterTest do
  use SiteWeb.ConnCase, async: true

  import Site.ContentRewriter
  import Mock
  import SiteWeb.PartialView.SvgIconWithCircle, only: [svg_icon_with_circle: 1]
  import Phoenix.HTML, only: [raw: 1, safe_to_string: 1]

  alias SiteWeb.PartialView.SvgIconWithCircle
  alias Site.ContentRewriters.ResponsiveTables

  describe "rewrite" do
    test "it returns non-table content unchanged", %{conn: conn} do
      original = raw("<div><span>Nothing to see here.</span></div>")
      assert rewrite(original, conn) == original
    end

    test "it dispatches to the table rewriter if a table is present", %{conn: conn} do
      with_mock ResponsiveTables, [rewrite_table: fn(_) -> {"table", [], []} end] do
        "<div><span>Foo</span><table>Foo</table></div>"
        |> raw()
        |> rewrite(conn)

        assert called ResponsiveTables.rewrite_table({"table", [], ["Foo"]})
      end
    end

    test "it handles a plain string", %{conn: conn} do
      original = raw("I'm a string")
      assert rewrite(original, conn) == original
    end

    test "the different rewriters work well together", %{conn: conn} do
      rewritten =
        ~s(
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
        )
        |> raw()
        |> rewrite(conn)

      expected =
        ~s(
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
        )

      assert remove_whitespace(safe_to_string(rewritten)) == remove_whitespace(expected)
    end

    test "strips dimension attributes from images", %{conn: conn} do
      assert ~s(<img src="/image.png" alt="an image" width="600" height="400"/>)
             |> raw()
             |> rewrite(conn) == {:safe, ~s(<img class="img-fluid" src="/image.png" alt="an image"/>)}
    end

    test "adds img-fluid to images that don't already have a class", %{conn: conn} do
      assert ~s(<img src="/image.png" alt="an image" />)
             |> raw()
             |> rewrite(conn) == {:safe, ~s(<img class="img-fluid" src="/image.png" alt="an image"/>)}
    end

    test "adds img-fluid to images that do already have a class", %{conn: conn} do
      assert ~s(<img src="/image.png" alt="an image" class="existing-class" />)
             |> raw()
             |> rewrite(conn) == {:safe, ~s(<img class="existing-class img-fluid" src="/image.png" alt="an image"/>)}
    end

    test "adds iframe classes to iframes", %{conn: conn} do
      assert ~s(<iframe src="https://www.anything.com"></iframe>)
             |> raw()
             |> rewrite(conn) == {:safe, ~s(<div class="iframe-container"><iframe class="iframe" src="https://www.anything.com"></iframe></div>)}
    end

    test "adds iframe-full-width class to google maps and livestream iframes", %{conn: conn} do
      assert {:safe, ~s(<div class="iframe-container"><iframe class="iframe iframe-full-width") <> _} =
        ~s(<iframe src="https://livestream.com/anything"></iframe>)
        |> raw()
        |> rewrite(conn)

      assert {:safe, ~s(<div class="iframe-container"><iframe class="iframe iframe-full-width") <> _} =
        ~s(<iframe src="https://www.google.com/maps/anything"></iframe>)
        |> raw()
        |> rewrite(conn)
    end

    test "removes incompatible CMS media embed and replaces with empty div", %{conn: conn} do
      rewritten =
        ~s(<figure class="embedded-entity align-right">
          <div><div class="media media--type-image media--view-mode-quarter"><div class="media-content">
          <img alt="My Image Alt Text" class="image-style-max-650x650"
          src="/sites/default/files/styles/max_650x650/public/2018-01/hingham-ferry-dock-repair.png?itok=YwrRrgrG"
          typeof="foaf:Image" height="488" width="650"></div></div></div>
          <figcaption>Right aligned third</figcaption></figure>)
        |> raw()
        |> rewrite(conn)
        |> safe_to_string()

      assert rewritten == ~s(<div class="incompatible-media"></div>)
    end

    test "rebuilds CMS media embed: third-size image | w/caption | aligned right | no link", %{conn: conn} do
      rewritten =
        ~s(<figure class="embedded-entity align-right">
          <div><div class="media media--type-image media--view-mode-third"><div class="media-content">
          <img alt="My Image Alt Text" class="image-style-max-650x650"
          src="/sites/default/files/styles/max_650x650/public/2018-01/hingham-ferry-dock-repair.png?itok=YwrRrgrG"
          typeof="foaf:Image" height="488" width="650"></div></div></div>
          <figcaption>Right aligned third</figcaption></figure>)
        |> raw()
        |> rewrite(conn)
        |> safe_to_string()

      assert rewritten =~ ~s(<figure class="c-media c-media--type-image c-media--size-third c-media--align-right">)
      assert rewritten =~ ~s(<img class="image-style-max-650x650 c-media__media-element img-fluid" alt="My Image Alt Text")
      assert rewritten =~ ~s(src="/sites/default/files/styles/max_650x650/public/2018-01/hingham-ferry-dock-repair.png?itok=YwrRrgrG")
      assert rewritten =~ ~s(<figcaption class="c-media__caption">Right aligned third</figcaption></figure>)
    end

    test "rebuilds CMS media embed: full-size image | w/o caption | no alignment | linked", %{conn: conn} do
      rewritten =
        ~s(<div class="embedded-entity"><a class="media-link"
          href="/projects/wollaston-station-improvements" target="_blank">
          <div class="media media--type-image media--view-mode-full"><div class="media-content">
          <img src="/sites/default/files/styles/max_2600x2600/public/2018-01/hingham-ferry-dock-repair.png?itok=NWs0V_7W"
          alt="My Image Alt Text" typeof="foaf:Image" class="image-style-max-2600x2600" height="756" width="1008"></div></div></a></div>)
        |> raw()
        |> rewrite(conn)
        |> safe_to_string()

      assert rewritten =~ ~s(<figure class="c-media c-media--type-image c-media--size-full c-media--align-none">)
      assert rewritten =~ ~s(<a class="c-media__link" href="/projects/wollaston-station-improvements" target="_blank">)
      assert rewritten =~ ~s(<img class="image-style-max-2600x2600 c-media__media-element img-fluid")
      assert rewritten =~ ~s(src="/sites/default/files/styles/max_2600x2600/public/2018-01/hingham-ferry-dock-repair.png?itok=NWs0V_7W" alt="My Image Alt Text")
      refute rewritten =~ ~s(<figcaption)
    end

  end

  defp remove_whitespace(str), do: String.replace(str, ~r/[ \n]/, "")

  defp svg_bus do
    %SvgIconWithCircle{icon: :bus}
    |> svg_icon_with_circle
    |> safe_to_string
  end
end
