defmodule SiteWeb.ContentViewTest do
  use Site.ViewCase, async: true

  import Content.Factory, only: [event_factory: 1, person_factory: 0]
  import SiteWeb.ContentView

  alias Content.BasicPage
  alias Content.CMS.Static
  alias Content.Field.{File, Link}
  alias Content.Paragraph.{Column, ColumnMulti, CustomHTML, FareCard, FilesGrid,
    PeopleGrid, Tab, Tabs, TitleCard, TitleCardSet, Unknown, UpcomingBoardMeetings}
  alias Phoenix.HTML

  describe "Basic Page" do
    setup do
      basic_page = BasicPage.from_api(Static.basic_page_with_sidebar_response())
      %{basic_page: basic_page}
    end

    test "renders a sidebar menu", %{basic_page: basic_page} do
      fake_conn = %{query_params: %{}, request_path: basic_page.sidebar_menu.links |> List.first |> Map.get(:url)}

      rendered =
        "page.html"
        |> render(page: basic_page, conn: fake_conn)
        |> HTML.safe_to_string

      assert rendered =~ ~s(c-cms--with-sidebar)
      assert rendered =~ ~s(c-cms--sidebar-left)
      assert rendered =~ ~s(c-cms--sidebar-after)
      assert rendered =~ "Logan Airport"
      assert rendered =~ ~s(<ul class="c-cms__sidebar-links">)
      assert rendered =~ ~s(c-cms__sidebar)
    end

    test "renders a page without a sidebar menu", %{basic_page: basic_page} do
      basic_page = %{basic_page | sidebar_menu: nil}
      fake_conn = %{request_path: "/"}

      rendered =
        "page.html"
        |> render(page: basic_page, conn: fake_conn)
        |> HTML.safe_to_string

      assert rendered =~ ~s(c-cms--no-sidebar)
      assert rendered =~ "Fenway Park"
      refute rendered =~ ~s(<ul class="sidebar-menu">)
    end
  end

  describe "render_paragraph/2" do
    test "renders a Content.Paragraph.CustomHTML", %{conn: conn} do
      paragraph = %CustomHTML{body: HTML.raw("<p>Hello</p>")}

      rendered =
        paragraph
        |> render_paragraph(conn)
        |> HTML.safe_to_string

      assert rendered == "<p>Hello</p>"
    end

    test "renders a Content.Paragraph.CustomHTML with rewritten body", %{conn: conn} do
      html = "<div><span>Foo</span><table>Foo</table></div>"
      paragraph = %CustomHTML{body: HTML.raw(html)}

      rendered =
        paragraph
        |> render_paragraph(conn)
        |> HTML.safe_to_string

      assert rendered =~ "responsive-table"
    end

    test "renders a Content.Paragraph.TitleCardSet", %{conn: conn} do
      paragraph = %TitleCardSet{
        title_cards: [
          %TitleCard{
            title: "Card 1",
            body: HTML.raw("<strong>Body 1</strong>"),
            link: %Link{url: "/relative/link"},
          },
          %TitleCard{
            title: "Card 2",
            body: HTML.raw("<strong>Body 2</strong>"),
            link: %Link{url: "https://www.example.com/another/link"},
          }
        ]
      }

      rendered =
        paragraph
        |> render_paragraph(conn)
        |> HTML.safe_to_string

      assert rendered =~ ~s(<div class="c-title-card__title c-title-card--link__title">Card 1</div>)
      assert rendered =~ "<strong>Body 1</strong>"
      assert rendered =~ ~s( href="/relative/link")

      assert rendered =~ ~s(<div class="c-title-card__title c-title-card--link__title">Card 2</div>)
      assert rendered =~ "<strong>Body 2</strong>"
      assert rendered =~ ~s( href="https://www.example.com/another/link")
    end

    test "renders a Content.Paragraph.TitleCardSet with content rewritten", %{conn: conn} do
      paragraph = %TitleCardSet{
        title_cards: [
          %TitleCard{
            title: ~s({{mbta-circle-icon "bus"}}),
            body: HTML.raw("<div><span>Foo</span><table>Foo</table></div>"),
            link: %Link{url: "/relative/link"},
          }
        ]
      }

      rendered =
        paragraph
        |> render_paragraph(conn)
        |> HTML.safe_to_string

      assert rendered =~ "responsive-table"
      refute rendered =~ "mbta-circle-icon"
    end

    test "renders a Content.Paragraph.UpcomingBoardMeetings", %{conn: conn} do
      event = event_factory(0)
      paragraph = %UpcomingBoardMeetings{
        events: [event]
      }

      rendered =
        paragraph
        |> render_paragraph(conn)
        |> HTML.safe_to_string

      rendered_title =
        event.title
        |> HTML.html_escape
        |> HTML.safe_to_string

      assert rendered =~ rendered_title
      assert rendered =~ "View all upcoming meetings"
    end

    test "renders a TitleCardSet when it doesn't have a link", %{conn: conn} do
      paragraph = %TitleCardSet{
        title_cards: [
          %TitleCard{
            title: "Title Card",
            body: HTML.raw("This is a title card"),
            link: nil,
          }
        ]
      }

      rendered =
        paragraph
        |> render_paragraph(conn)
        |> HTML.safe_to_string

      assert rendered =~ "This is a title card"
    end

    test "renders a Paragraph.PeopleGrid", %{conn: conn} do
      person = person_factory()

      paragraph = %PeopleGrid{
        people: [person]
      }

      rendered =
        paragraph
        |> render_paragraph(conn)
        |> HTML.safe_to_string

      assert rendered =~ person.name
      assert rendered =~ person.position
    end

    test "renders a FareCard", %{conn: conn} do
      paragraph = %ColumnMulti{
        columns: [
          %Column{
            paragraphs: [
              %FareCard{
                fare_token: "subway:charlie_card",
                note: %CustomHTML{
                  body: {:safe, "<p>{{ fare:subway:cash }} with CharlieTicket</p>\n"}
                }
              }
            ]
          },
          %Column{
            paragraphs: [
              %FareCard{
                fare_token: "local_bus:charlie_card",
                note: %CustomHTML{
                  body: {:safe,
                   "<p>{{ fare:local_bus:cash }} with CharlieTicket</p>\n"}
                }
              }
            ]
          }
        ]
      }

      rendered =
        paragraph
        |> render_paragraph(conn)
        |> HTML.safe_to_string()

      assert rendered =~ "Subway"
      assert rendered =~ "One-Way"
      assert rendered =~ "$2.25"
      assert rendered =~ "with a CharlieCard"
      assert rendered =~ "$2.75 with CharlieTicket"
      assert rendered =~ "Local Bus"
      assert rendered =~ "$1.70"
      assert rendered =~ "$2.00 with CharlieTicket"
    end

    test "renders a grouped FareCard", %{conn: conn} do
      paragraph = %ColumnMulti{
        columns: [
          %Column{
            paragraphs: [
              %FareCard{
                fare_token: "local_bus:charlie_card",
                note: %CustomHTML{
                  body: {:safe, "<p>1 free transfer to Local Bus within 2 hours</p>\n"}
                }
              }
            ]
          },
          %Column{
            paragraphs: [
              %FareCard{
                fare_token: "local_bus:cash",
                note: %CustomHTML{
                  body: {:safe,
                   "<p>a href='/schedules/bus'>Limited transfers</a></p>\n"}
                }
              }
            ]
          }
        ],
        display_options: "grouped"
      }

      rendered =
        paragraph
        |> render_paragraph(conn)
        |> HTML.safe_to_string()

      assert rendered =~ "fare-card--grouped"
      assert rendered =~ "Local Bus"
      assert rendered =~ "One-Way"
      assert rendered =~ "$1.70"
      assert rendered =~ "with a CharlieCard"
      assert rendered =~ "1 free transfer"
      assert rendered =~ "$2.00"
      assert rendered =~ "with a CharlieTicket or Cash"
      assert rendered =~ "Limited transfers"
    end

    test "renders a Paragraph.FilesGrid without a title", %{conn: conn} do
      paragraph = %FilesGrid{title: nil, files: [%File{url: "/link", description: "link description"}]}

      rendered =
        paragraph
        |> render_paragraph(conn)
        |> HTML.safe_to_string

      assert rendered =~ "link description"
    end

    test "renders a Paragraph.FilesGrid with a title", %{conn: conn} do
      paragraph = %FilesGrid{files: [%File{}], title: "Some files"}

      rendered =
        paragraph
        |> render_paragraph(conn)
        |> HTML.safe_to_string

      assert rendered =~ paragraph.title
    end

    test "renders a Content.Paragraph.ColumnMulti with nested paragraphs", %{conn: conn} do
      header = %Content.Paragraph.ColumnMultiHeader{
        text: HTML.raw("<h4>This is a multi-column header</h4>")
      }
      cols = [
        %Column{
          paragraphs: [
            %CustomHTML{body: HTML.raw("<strong>Column 1</strong>")}
          ]
        },
        %Column{
          paragraphs: [
            %CustomHTML{body: HTML.raw("<strong>Column 2</strong>")}
          ]
        },
        %Column{
          paragraphs: [
            %CustomHTML{body: HTML.raw("<strong>Column 3</strong>")}
          ]
        },
        %Column{
          paragraphs: [
            %CustomHTML{body: HTML.raw("<strong>Column 4</strong>")}
          ]
        }
      ]

      rendered_quarters =
        %ColumnMulti{header: header, columns: cols}
        |> render_paragraph(conn)
        |> HTML.safe_to_string

      rendered_thirds =
        %ColumnMulti{header: header, columns: Enum.take(cols, 3)}
        |> render_paragraph(conn)
        |> HTML.safe_to_string

      rendered_halves =
        %ColumnMulti{header: header, columns: Enum.take(cols, 2)}
        |> render_paragraph(conn)
        |> HTML.safe_to_string

      rendered_single =
        %ColumnMulti{header: header, columns: Enum.take(cols, 1)}
        |> render_paragraph(conn)
        |> HTML.safe_to_string

      assert rendered_quarters =~ "<h4>This is a multi-column header</h4>"
      assert rendered_quarters =~ ~r/<div class=\"col-md-3\">\s*<strong>Column 1<\/strong>/
      assert rendered_quarters =~ ~r/<div class=\"col-md-3\">\s*<strong>Column 2<\/strong>/
      assert rendered_quarters =~ ~r/<div class=\"col-md-3\">\s*<strong>Column 3<\/strong>/
      assert rendered_quarters =~ ~r/<div class=\"col-md-3\">\s*<strong>Column 4<\/strong>/

      assert rendered_thirds =~ "<h4>This is a multi-column header</h4>"
      assert rendered_thirds =~ ~r/<div class=\"col-md-4\">\s*<strong>Column 1<\/strong>/
      assert rendered_thirds =~ ~r/<div class=\"col-md-4\">\s*<strong>Column 2<\/strong>/
      assert rendered_thirds =~ ~r/<div class=\"col-md-4\">\s*<strong>Column 3<\/strong>/

      assert rendered_halves =~ "<h4>This is a multi-column header</h4>"
      assert rendered_halves =~ ~r/<div class=\"col-md-6\">\s*<strong>Column 1<\/strong>/
      assert rendered_halves =~ ~r/<div class=\"col-md-6\">\s*<strong>Column 2<\/strong>/

      assert rendered_single =~ "<h4>This is a multi-column header</h4>"
      assert rendered_single =~ ~r/<div class=\"row\">\s*<div class=\"col-md-6\">\s*<strong>Column 1<\/strong>/
    end

    test "renders a Content.Paragraph.Tabs", %{conn: conn} do
      tabs = [
        %Tab{
          title: "{{ icon:subway-red }} Tab 1",
          prefix: "cms-10",
          content: %CustomHTML{
            body: HTML.raw("<strong>First tab's content</strong>")
          },
        },
        %Tab{
          title: "Tab 2",
          prefix: "cms-11",
          content: %CustomHTML{
            body: HTML.raw("<strong>Second tab's content</strong>")
          }
        }
      ]

      rendered_tabs =
        %Tabs{display: "accordion", tabs: tabs}
        |> render_paragraph(conn)
        |> HTML.safe_to_string()

      [{_, _, [icon_1 | [title_1]]}, {_, _, [title_2]}] = Floki.find(rendered_tabs, ".c-tabbed-ui__title")
      [{_, _, [body_1]}, {_, _, [body_2]}] = Floki.find(rendered_tabs, ".c-tabbed-ui__target > .c-tabbed-ui__content")
      [{_, [_, {"href", href_1}, _, _, {"aria-controls", aria_controls_1}, _, {"data-parent", parent_1}], _},
       {_, [_, {"href", href_2}, _, _, {"aria-controls", aria_controls_2}, _, {"data-parent", parent_2}], _}] =
       Floki.find(rendered_tabs, ".c-tabbed-ui__trigger")

      assert {"span", [{"data-toggle", "tooltip"}, {"title", "Red Line"}], [{"span", [{"class", "notranslate c-svg__icon-red-line-default"}], _}]} = icon_1
      assert title_1 =~ ~r/\s*Tab 1\s*/
      assert title_2 =~ ~r/\s*Tab 2\s*/
      assert href_1 == "#cms-10-tab"
      assert href_2 == "#cms-11-tab"
      assert aria_controls_1 == "cms-10-tab"
      assert aria_controls_2 == "cms-11-tab"
      assert parent_1 == "#tab-group"
      assert parent_1 == parent_2
      assert Floki.raw_html(body_1, encode: false) =~ "First tab's content"
      assert Floki.raw_html(body_2, encode: false) =~ "Second tab's content"
    end

    test "renders a Paragraph.Unknown", %{conn: conn} do
      paragraph = %Unknown{
        type: "unsupported_paragraph_type"
      }

      rendered =
        paragraph
        |> render_paragraph(conn)
        |> HTML.safe_to_string()

      assert rendered =~ paragraph.type
    end
  end

  describe "file_description/1" do
    test "returns URL decoded file name if description is nil" do
      file = %File{url: "/some/path/This%20File%20Is%20Great.pdf", description: nil}
      assert file_description(file) == "This File Is Great.pdf"
    end

    test "returns the URL decoded file name if description is an empty string" do
      file = %File{url: "/some/path/This%20File%20Is%20Great.pdf", description: ""}
      assert file_description(file) == "This File Is Great.pdf"
    end

    test "returns the description if present" do
      file = %File{url: "/some/path/This%20File%20Is%20Great.pdf", description: "Download Now"}
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

  describe "grid/1" do
    test "returns the size of our grid based on the number of columns" do
      column_multi_2 = %ColumnMulti{
        columns: [
          %Column{
            paragraphs: [
              %CustomHTML{body: HTML.raw("<strong>Column 1</strong>")}
            ]
          },
          %Column{
            paragraphs: [
              %CustomHTML{body: HTML.raw("<strong>Column 2</strong>")}
            ]
          }
        ]
      }

      assert grid(column_multi_2) == 6
    end

    test "limits to a max size of 6" do
      column_multi_1 = %ColumnMulti{
        columns: [
          paragraphs: [
            %CustomHTML{body: HTML.raw("<strong>Column 1</strong>")}
          ]
        ]
      }

      assert grid(column_multi_1) == 6
    end
  end

  describe "extend_width_if/2" do
    test "wraps content with media divs if the condition is true" do
      rendered = extend_width_if(true, do: "foo") |> HTML.safe_to_string

      assert rendered =~ "c-media c-media--type-table"
      assert rendered =~ "c-media__content"
      assert rendered =~ "c-media__element"
      assert rendered =~ "foo"
    end

    test "wraps content with nothing if the condition is false" do
      assert extend_width_if(false, do: "foo") == "foo"
    end
  end
end
