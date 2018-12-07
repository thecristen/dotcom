defmodule Content.ParagraphTest do
  use ExUnit.Case, async: true

  import Content.Paragraph
  import Phoenix.HTML, only: [safe_to_string: 1]

  alias Content.CMS.Static
  alias Content.Event
  alias Content.Field.File

  alias Content.Paragraph.{
    Column,
    ColumnMulti,
    ColumnMultiHeader,
    CustomHTML,
    Description,
    DescriptionList,
    FareCard,
    FilesGrid,
    PeopleGrid,
    Tab,
    Tabs,
    TitleCard,
    TitleCardSet,
    Unknown,
    UpcomingBoardMeetings
  }

  alias Content.Person

  describe "from_api/1" do
    test "parses custom html" do
      api_data = api_paragraph("custom_html")

      assert %CustomHTML{
               body: body
             } = from_api(api_data)

      assert safe_to_string(body) =~ ~s(This page demonstrates all the "paragraphs" available)
    end

    test "parses a description list paragraph" do
      description_list_data = api_paragraph("description_list")

      assert %DescriptionList{
               header: header,
               descriptions: [
                 %Description{
                   term: term1,
                   details: details1
                 },
                 %Description{
                   term: term2,
                   details: details2
                 }
               ]
             } = from_api(description_list_data)

      assert %ColumnMultiHeader{} = header

      assert safe_to_string(header.text) =~
               "<p>1-day and 7-day passes purchased on CharlieTickets"

      assert safe_to_string(term1) =~ "<p>1-Day Pass</p>"
      assert safe_to_string(details1) =~ "Unlimited travel for 24 hours"
      assert safe_to_string(term2) =~ "<p>7-Day Pass</p>"
      assert safe_to_string(details2) =~ "Unlimited travel for 7 days"
    end

    test "parses a fare card paragraph" do
      api_data = api_paragraph_by_id(4192)

      assert %ColumnMulti{
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
                         body: {:safe, "<p>{{ fare:local_bus:cash }} with CharlieTicket</p>\n"}
                       }
                     }
                   ]
                 }
               ]
             } = from_api(api_data)
    end

    test "parses a files grid paragraph" do
      api_data = api_paragraph("files_grid")

      assert %FilesGrid{
               title: nil,
               files: [%File{}, %File{}, %File{}, %File{}]
             } = from_api(api_data)
    end

    test "parses multi column paragraph" do
      multi_column = "multi_column" |> api_paragraph() |> from_api()

      assert %ColumnMulti{
               columns: [
                 %Column{
                   paragraphs: [
                     %Content.Paragraph.CustomHTML{} = column1_paragraph1
                   ]
                 },
                 %Column{
                   paragraphs: [
                     %Content.Paragraph.CustomHTML{} = column2_paragraph1
                   ]
                 }
               ],
               header: header
             } = multi_column

      assert %ColumnMultiHeader{} = header
      assert safe_to_string(header.text) =~ "<h4>This is a new paragraph type's sub field.</h4>"

      assert safe_to_string(column1_paragraph1.body) =~
               "<p>This is a Custom HTML paragraph inside the Column paragraph"

      assert safe_to_string(column2_paragraph1.body) =~
               "<h4>Multi-column vs. Title card set</h4>\n\n<p>We recommend"
    end

    test "parses a multi-column paragraph with display options" do
      api_data = api_paragraph_by_id(4472)

      assert %ColumnMulti{
               columns: [
                 %Column{paragraphs: [%FareCard{}]},
                 %Column{paragraphs: [%FareCard{}]}
               ],
               display_options: "grouped"
             } = from_api(api_data)
    end

    test "returns the correct struct when given a people grid paragraph" do
      api_data = api_paragraph("people_grid")

      assert %PeopleGrid{
               people: [
                 %Person{id: 2605},
                 %Person{id: 2610},
                 %Person{id: 2609}
               ]
             } = from_api(api_data)
    end

    test "parses tabbed interface paragraph (tabs)" do
      api_data = api_paragraph("tabs")

      assert %Tabs{
               display: "collapsible",
               tabs: [
                 %Tab{} = tab1,
                 %Tab{} = tab2
               ]
             } = from_api(api_data)

      assert tab1.title == "Accordion Tab Label 1"
      assert tab2.title == "Accordion Tab Label 2"

      assert %CustomHTML{} = tab1.content
      assert %CustomHTML{} = tab2.content
    end

    test "parses title card set" do
      api_data = api_paragraph("title_card_set")

      assert %TitleCardSet{
               title_cards: [
                 %TitleCard{} = title_card1,
                 %TitleCard{}
               ]
             } = from_api(api_data)

      assert title_card1.title == "Example Card 1"
      assert safe_to_string(title_card1.body) =~ "<p>The body of the title card"
    end

    test "parses upcoming board meetings" do
      api_data = api_paragraph("upcoming_board_meetings")

      assert %UpcomingBoardMeetings{
               events: [
                 %Event{id: 3269},
                 %Event{id: 3318},
                 %Event{id: 3306},
                 %Event{id: 3291}
               ]
             } = from_api(api_data)
    end

    test "parses an unknown paragraph type" do
      api_data = %{
        "type" => [%{"target_id" => "unsupported_paragraph_type"}]
      }

      assert %Unknown{
               type: "unsupported_paragraph_type"
             } = from_api(api_data)
    end
  end

  defp api_paragraph(paragraph_type) do
    Static.all_paragraphs_response()
    |> Map.get("field_paragraphs")
    |> Enum.find(&match?(%{"type" => [%{"target_id" => ^paragraph_type}]}, &1))
  end

  defp api_paragraph_by_id(id) do
    Static.all_paragraphs_response()
    |> Map.get("field_paragraphs")
    |> Enum.find(&match?(%{"id" => [%{"value" => ^id}]}, &1))
  end
end
