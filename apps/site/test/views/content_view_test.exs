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
            link: %Content.Field.Link{url: "/relative/link"},
          },
          %Paragraph.TitleCard{
            title: "Card 2",
            body: Phoenix.HTML.raw("<strong>Body 2</strong>"),
            link: %Content.Field.Link{url: "https://www.example.com/another/link"},
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

    test "renders a Paragraph.FilesGrid without a title" do
      paragraph = %Paragraph.FilesGrid{title: nil, files: [%Content.Field.File{url: "/link", description: "link description"}]}

      rendered =
        paragraph
        |> render_paragraph
        |> Phoenix.HTML.safe_to_string

      assert rendered =~ "link description"
    end

    test "renders a Paragraph.FilesGrid with a title" do
      paragraph = %Paragraph.FilesGrid{files: [%Content.Field.File{}], title: "Some files"}

      rendered =
        paragraph
        |> render_paragraph
        |> Phoenix.HTML.safe_to_string

      assert rendered =~ paragraph.title
    end

    test "renders a Paragraph.CallToAction" do
      paragraph = %Paragraph.CallToAction{
        link: %Content.Field.Link{
          url: "www.example.com",
          title: "See example"
        }
      }

      rendered =
        paragraph
        |> render_paragraph()
        |> Phoenix.HTML.safe_to_string()

      assert rendered =~ paragraph.link.url
      assert rendered =~ paragraph.link.title
    end

    test "renders a Paragraph.Unknown" do
      paragraph = %Paragraph.Unknown{
        type: "unsupported_paragraph_type"
      }

      rendered =
        paragraph
        |> render_paragraph()
        |> Phoenix.HTML.safe_to_string()

      assert rendered =~ paragraph.type
    end
  end

  describe "file_description/1" do
    test "returns URL decoded file name if description is nil" do
      file = %Content.Field.File{url: "/some/path/This%20File%20Is%20Great.pdf", description: nil}
      assert file_description(file) == "This File Is Great.pdf"
    end

    test "returns the URL decoded file name if description is an empty string" do
      file = %Content.Field.File{url: "/some/path/This%20File%20Is%20Great.pdf", description: ""}
      assert file_description(file) == "This File Is Great.pdf"
    end

    test "returns the description if present" do
      file = %Content.Field.File{url: "/some/path/This%20File%20Is%20Great.pdf", description: "Download Now"}
      assert file_description(file) == "Download Now"
    end
  end
end
