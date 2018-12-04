defmodule Content.Paragraph.ColumnMultiTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Content.Paragraph.{Column, ColumnMulti, CustomHTML, FareCard}
  alias Phoenix.HTML

  test "is_grouped?/1 returns whether or not the ColumnMulti paragraph is grouped" do
    grouped_column_multi = %ColumnMulti{display_options: "grouped"}
    ungrouped_column_multi = %ColumnMulti{display_options: "default"}

    assert ColumnMulti.is_grouped?(grouped_column_multi)
    refute ColumnMulti.is_grouped?(ungrouped_column_multi)
  end

  test "includes_fare_cards?/1 returns whether or not the ColumnMulti paragraph contains a fare card" do
    column_multi_with_fare_card = %ColumnMulti{
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
        }
      ]
    }
    column_multi_without_fare_card = %ColumnMulti{
      columns: [
        %Column{
          paragraphs: [
            %CustomHTML{body: HTML.raw("<strong>Column 1</strong>")}
          ]
        }
      ]
    }

    assert ColumnMulti.includes_fare_cards?(column_multi_with_fare_card)
    refute ColumnMulti.includes_fare_cards?(column_multi_without_fare_card)
  end

end
