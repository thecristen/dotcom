defmodule Content.ParagraphTest do
  use ExUnit.Case, async: true

  import Content.Paragraph
  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "from_api/1" do
    test "parses custom html" do
      api_data = api_paragraph("custom_html")

      assert %Content.Paragraph.CustomHTML{
        body: body
      } = from_api(api_data)

      assert safe_to_string(body) =~ ~s(This page demonstrates all the "paragraphs" available)
    end

    test "parses title card set" do
      api_data = api_paragraph("title_card_set")

      assert %Content.Paragraph.TitleCardSet{
        title_cards: [
          %Content.Paragraph.TitleCard{} = title_card1,
          %Content.Paragraph.TitleCard{}
        ]
      } = from_api(api_data)

      assert title_card1.title == "Example Card 1"
      assert safe_to_string(title_card1.body) =~ "<p>The body of the title card"
    end

    test "parses upcoming board meetings" do
      api_data = api_paragraph("upcoming_board_meetings")

      assert %Content.Paragraph.UpcomingBoardMeetings{
        events: [
          %Content.Event{id: 3269},
          %Content.Event{id: 3318},
          %Content.Event{id: 3306},
          %Content.Event{id: 3291}
        ]
      } = from_api(api_data)
    end

    test "returns the correct struct when given a people grid paragraph" do
      api_data = api_paragraph("people_grid")

      assert %Content.Paragraph.PeopleGrid{
        people: [
          %Content.Person{id: 2605},
          %Content.Person{id: 2610},
          %Content.Person{id: 2609},
        ]
      } = from_api(api_data)
    end

    test "parses a files grid paragraph" do
      api_data = api_paragraph("files_grid")

      assert %Content.Paragraph.FilesGrid{
        title: nil,
        files: [%Content.Field.File{}, %Content.Field.File{}, %Content.Field.File{}, %Content.Field.File{}]
      } = from_api(api_data)
    end

    test "parses the call to action paragraph" do
      api_data = api_paragraph("call_to_action")

      assert %Content.Paragraph.CallToAction{
        link: %Content.Field.Link{
          url: "http://www.google.com",
          title: "Continue reading..."
        }
      } = from_api(api_data)
    end

    test "parses an unknown paragraph type" do
      api_data = %{
        "type" => [%{"target_id" => "unsupported_paragraph_type"}]
      }

      assert %Content.Paragraph.Unknown{
        type: "unsupported_paragraph_type"
      } = from_api(api_data)
    end
  end

  test "parses multi column paragraph" do
    api_data = api_paragraph("multi_column")

    assert %Content.Paragraph.ColumnMulti{
      columns: [
        %Content.Paragraph.Column{} = column1,
        %Content.Paragraph.Column{} = column2
      ]
    } = from_api(api_data)

    assert safe_to_string(column1.body) =~ "<h4>Basic Format</h4><p>The multi-column"
    assert safe_to_string(column2.body) =~ "<h4>Multi-column vs. Title card set</h4><p>We recommend"
  end

  test "parses tabbed interface paragraph (tabs)" do
    api_data = api_paragraph("tabs")

    assert %Content.Paragraph.Tabs{
      display: "collapsible",
      tabs: [
        %Content.Paragraph.Tab{} = tab1,
        %Content.Paragraph.Tab{} = tab2
      ]
    } = from_api(api_data)

    assert tab1.title == "Accordion Tab Label 1"
    assert tab2.title == "Accordion Tab Label 2"

    assert %Content.Paragraph.CustomHTML{} = tab1.content
    assert %Content.Paragraph.CustomHTML{} = tab2.content
  end

  defp api_paragraph(paragraph_type) do
    Content.CMS.Static.all_paragraphs_response()
    |> Map.get("field_paragraphs")
    |> Enum.find(& match?(%{"type" => [%{"target_id" => ^paragraph_type}]}, &1))
  end
end
