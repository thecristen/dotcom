defmodule Content.ParagraphTest do
  use ExUnit.Case, async: true

  import Content.FixtureHelpers
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
      api_data = parse_json_file("priv/upcoming_board_meetings_paragraph.json")

      assert %Content.Paragraph.UpcomingBoardMeetings{
        events: [
          %Content.Event{id: 1},
          %Content.Event{id: 2}
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
        url: "https://t.mbta.com/schedules",
        text: "MBTA Schedules"
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

  defp api_paragraph(paragraph_type) do
    Content.CMS.Static.all_paragraphs_response()
    |> Map.get("field_paragraphs")
    |> Enum.find(& match?(%{"type" => [%{"target_id" => ^paragraph_type}]}, &1))
  end
end
