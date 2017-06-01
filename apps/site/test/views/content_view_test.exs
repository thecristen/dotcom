defmodule Site.ContentViewTest do
  use ExUnit.Case, async: true

  import Site.ContentView

  describe "render_paragraph/1" do
    test "renders a Content.Paragraph.CustomHTML" do
      paragraph = %Content.Paragraph.CustomHTML{body: Phoenix.HTML.raw("<p>Hello</p>")}

      rendered =
        paragraph
        |> render_paragraph
        |> Phoenix.HTML.safe_to_string

      assert rendered == "<p>Hello</p>"
    end

    test "renders a Content.Paragraph.TitleCardSet" do
      paragraph = %Content.Paragraph.TitleCardSet{
        title_cards: [
          %Content.Paragraph.TitleCard{
            title: "Card 1",
            body: Phoenix.HTML.raw("<strong>Body 1</strong>"),
            link: "/relative/link",
          },
          %Content.Paragraph.TitleCard{
            title: "Card 2",
            body: Phoenix.HTML.raw("<strong>Body 2</strong>"),
            link: "https://www.example.com/another/link",
          }
        ]
      }

      rendered =
        paragraph
        |> render_paragraph
        |> Phoenix.HTML.safe_to_string

      assert rendered =~ ~s(<div class="title-card-title">Card 1</div>)
      assert rendered =~ "<strong>Body 1</strong>"
      assert rendered =~ ~s( href="/relative/link")

      assert rendered =~ ~s(<div class="title-card-title">Card 2</div>)
      assert rendered =~ "<strong>Body 2</strong>"
      assert rendered =~ ~s( href="https://www.example.com/another/link")
    end
  end
end
