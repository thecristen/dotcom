defmodule Content.Paragraph.ColumnMulti do
  @moduledoc """
  A set of columns to organize layout on the page.
  """
  alias Content.Helpers
  alias Content.Paragraph.{Column, ColumnMultiHeader, DescriptiveLink, FareCard}

  defstruct header: nil,
            columns: [],
            display_options: nil,
            right_rail: false

  @type t :: %__MODULE__{
          header: ColumnMultiHeader.t(),
          columns: [Column.t()],
          display_options: String.t(),
          right_rail: boolean
        }

  @spec from_api(map) :: t
  def from_api(data) do
    header =
      data
      |> Map.get("field_multi_column_header", [])
      |> Enum.map(&ColumnMultiHeader.from_api/1)
      # There is only ever 1 header element
      |> List.first()

    columns =
      data
      |> Map.get("field_column", [])
      |> Enum.map(&Column.from_api/1)

    display_options = Helpers.field_value(data, "field_display_options")

    right_rail = Helpers.field_value(data, "field_right_rail")

    %__MODULE__{
      header: header,
      columns: columns,
      display_options: display_options,
      right_rail: right_rail
    }
  end

  @spec is_grouped?(__MODULE__.t()) :: boolean
  def is_grouped?(%__MODULE__{display_options: "grouped"}), do: true
  def is_grouped?(_), do: false

  @spec includes_cards?(__MODULE__.t()) :: boolean
  def includes_cards?(%__MODULE__{columns: columns}) do
    columns
    |> Enum.flat_map(& &1.paragraphs)
    |> Enum.any?(&is_a_card?/1)
  end

  defp is_a_card?(%FareCard{}), do: true
  defp is_a_card?(%DescriptiveLink{}), do: true
  defp is_a_card?(_), do: false
end
