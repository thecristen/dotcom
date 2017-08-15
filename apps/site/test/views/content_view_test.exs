defmodule Site.ContentViewTest do
  use ExUnit.Case, async: true

  import Content.Factory, only: [event_factory: 0, person_factory: 0]
  import Site.ContentView

  alias Content.Paragraph

  describe "Basic Page" do
    setup do
      basic_page = Content.BasicPage.from_api(Content.CMS.Static.basic_page_with_sidebar_response())
      %{basic_page: basic_page}
    end

    test "renders a sidebar menu", %{basic_page: basic_page} do
      fake_conn = %{request_path: basic_page.sidebar_menu.links |> List.first |> Map.get(:url)}

      rendered =
        "page.html"
        |> render(page: basic_page, conn: fake_conn)
        |> Phoenix.HTML.safe_to_string

      assert rendered =~ "Parking Info by Station"
      assert rendered =~ ~s(<ul class="sidebar-menu">)
    end

    test "renders a page without a sidebar menu", %{basic_page: basic_page} do
      basic_page = %{basic_page | sidebar_menu: nil}
      fake_conn = %{request_path: "/"}

      rendered =
        "page.html"
        |> render(page: basic_page, conn: fake_conn)
        |> Phoenix.HTML.safe_to_string

      assert rendered =~ "Parking Info by Station"
      refute rendered =~ ~s(<ul class="sidebar-menu">)
    end
  end

  describe "render_paragraph/1" do
    test "renders a Content.Paragraph.CustomHTML" do
      paragraph = %Paragraph.CustomHTML{body: Phoenix.HTML.raw("<p>Hello</p>")}

      rendered =
        paragraph
        |> render_paragraph
        |> Phoenix.HTML.safe_to_string

      assert rendered == "<p>Hello</p>"
    end

    test "renders a Content.Paragraph.CustomHTML with rewritten body" do
      html = "<div><span>Foo</span><table>Foo</table></div>"
      paragraph = %Paragraph.CustomHTML{body: Phoenix.HTML.raw(html)}

      rendered =
        paragraph
        |> render_paragraph
        |> Phoenix.HTML.safe_to_string

      assert rendered =~ "responsive-table"
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

    test "renders a Content.Paragraph.TitleCardSet with content rewritten" do
      paragraph = %Paragraph.TitleCardSet{
        title_cards: [
          %Paragraph.TitleCard{
            title: ~s({{mbta-circle-icon "bus"}}),
            body: Phoenix.HTML.raw("<div><span>Foo</span><table>Foo</table></div>"),
            link: %Content.Field.Link{url: "/relative/link"},
          }
        ]
      }

      rendered =
        paragraph
        |> render_paragraph
        |> Phoenix.HTML.safe_to_string

      assert rendered =~ "responsive-table"
      refute rendered =~ "mbta-circle-icon"
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

  describe "render_duration/2" do
    test "with no end time, only renders start time" do
      actual = render_duration(~N[2016-11-15T10:00:00], nil)
      expected = "November 15, 2016 at 10:00am"
      assert expected == actual
    end

    test "with start/end on same day, only renders date once" do
      actual = render_duration(~N[2016-11-14T12:00:00], ~N[2016-11-14T14:30:00])
      expected = "November 14, 2016 at 12:00pm - 2:30pm"
      assert expected == actual
    end

    test "with start/end on different days, renders both dates" do
      actual = render_duration(~N[2016-11-14T12:00:00], ~N[2016-12-01T14:30:00])
      expected = "November 14, 2016 12:00pm - December 1, 2016 2:30pm"
      assert expected == actual
    end

    test "with DateTimes, shifts them to America/New_York" do
      actual = render_duration(
                              Timex.to_datetime(~N[2016-11-05T05:00:00], "Etc/UTC"),
                              Timex.to_datetime(~N[2016-11-06T06:00:00], "Etc/UTC"))
      # could also be November 6th, 1:00 AM (test daylight savings)
      expected = "November 5, 2016 1:00am - November 6, 2016 2:00am"
      assert expected == actual
    end
  end
end
