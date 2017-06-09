defmodule Content.ParagraphTest do
  use ExUnit.Case, async: true

  import Content.Paragraph

  describe "from_api/1" do
    test "parses custom html" do
      api_data = api_paragraph("custom_html")

      assert from_api(api_data) == %Content.Paragraph.CustomHTML{
        body: Phoenix.HTML.raw("<p><strong>This is a Custom HTML paragraph.</strong></p>")
      }
    end

    test "parses title card set" do
      api_data = api_paragraph("title_card_set")

      assert from_api(api_data) == %Content.Paragraph.TitleCardSet{
        title_cards: [
          %Content.Paragraph.TitleCard{
            title: "Title Card Title",
            body: Phoenix.HTML.raw("<p>Title Card <strong>BODY</strong></p>"),
            link: "/some/internal/link"
          }
        ]
      }
    end
  end

  defp api_paragraph(paragraph_type) do
    Content.CMS.Static.all_paragraphs_response()
    |> Map.get("field_paragraphs")
    |> Enum.find(& match?(%{"type" => [%{"target_id" => ^paragraph_type}]}, &1))
  end
end
