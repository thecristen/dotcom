defmodule Site.ContentRewriters.ResponsiveTablesTest do
  use ExUnit.Case, async: true

  import Site.ContentRewriters.ResponsiveTables

  describe "rewrite_table" do
    test "works with a full table" do
      rewritten =
        """
          <table>
            This is the caption
            #{thead()}
            #{tbody()}
          </table>
        """
        |> Floki.parse
        |> rewrite_table

      assert rewritten == {
        "table", [{"class", "responsive-table"}], [
          {"caption", [], ["This is the caption"]},
          {"thead", [], [
            {"tr", [], [
              {"th", [{"scope", "col"}], ["Col1"]},
              {"th", [{"scope", "col"}], ["Col2"]}
            ]}
          ]},
          {"tbody", [], [
            {"tr", [], [
              {"th", [], ["Col1"]},
              {"td", [], ["Cell1"]},
              {"th", [], ["Col2"]},
              {"td", [], ["Cell2"]},
            ]},
            {"tr", [], [
              {"th", [], ["Col1"]},
              {"td", [], ["Cell3"]},
              {"th", [], ["Col2"]},
              {"td", [], ["Cell4"]},
            ]}
          ]}
        ]}
    end

    test "finds caption when it's a tag" do
      rewritten =
        """
          <table>
            <caption>Caption in tag</caption>
            #{thead()}
            #{tbody()}
          </table>
        """
        |> Floki.parse
        |> rewrite_table

      assert [{"caption", [], ["Caption in tag"]}] = Floki.find(rewritten, "caption")
    end

    test "gracefully handles an invalid table" do
      rewritten =
        "<table></table>"
        |> Floki.parse
        |> rewrite_table

      assert rewritten == {
        "table", [{"class", "responsive-table"}], [
          {"caption", [], [""]},
          {"thead", [], []},
          {"tbody", [], []}
        ]
      }
    end
  end

  def thead do
    """
      <thead>
        <tr>
          <th scope="col">Col1</th>
          <th scope="col">Col2</th>
        </tr>
      </thead>
    """
  end

  def tbody do
    """
      <tbody>
        <tr>
          <td>Cell1</td>
          <td>Cell2</td>
        </tr>
        <tr>
          <td>Cell3</td>
          <td>Cell4</td>
        </tr>
      </tbody>
    """
  end
end
