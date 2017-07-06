defmodule Site.ContentViewTest do
  use ExUnit.Case, async: true

  import Content.Factory, only: [event_factory: 0, person_factory: 0]
  import Site.ContentView

  alias Content.Paragraph

  describe "render_paragraph/1" do
    test "renders a Content.Paragraph.CustomHTML" do
      paragraph = %Paragraph.CustomHTML{body: Phoenix.HTML.raw("<p>Hello</p>")}

      rendered =
        paragraph
        |> render_paragraph
        |> Phoenix.HTML.safe_to_string

      assert rendered == "<p>Hello</p>"
    end

    test "renders a Content.Paragraph.TitleCardSet" do
      paragraph = %Paragraph.TitleCardSet{
        title_cards: [
          %Paragraph.TitleCard{
            title: "Card 1",
            body: Phoenix.HTML.raw("<strong>Body 1</strong>"),
            link: "/relative/link",
          },
          %Paragraph.TitleCard{
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

    test "renders a Content.Paragraph.UpcomingBoardMeetings" do
      event = event_factory()
      paragraph = %Paragraph.UpcomingBoardMeetings{
        events: [event]
      }

      rendered =
        paragraph
        |> render_paragraph()
        |> Phoenix.HTML.safe_to_string

      assert rendered =~ Phoenix.HTML.safe_to_string(event.title)
      assert rendered =~ "View all upcoming meetings"
    end

    test "renders a Paragraph.PeopleGrid" do
      person = person_factory()

      paragraph = %Paragraph.PeopleGrid{
        people: [person]
      }

      rendered =
        paragraph
        |> render_paragraph
        |> Phoenix.HTML.safe_to_string

      assert rendered =~ person.name
      assert rendered =~ person.position
    end
  end
end
