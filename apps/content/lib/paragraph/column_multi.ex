defmodule Content.Paragraph.ColumnMulti do
  @moduledoc """
  A set of columns to organize layout on the page.
  """
  alias Content.Helpers
  alias Content.Paragraph.{Column, ColumnMultiHeader, FareCard}

  defstruct header: nil,
            columns: [],
            display_options: nil

  @type t :: %__MODULE__{
          header: ColumnMultiHeader.t(),
          columns: [Column.t()],
          display_options: String.t()
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

    %__MODULE__{
      header: header,
      columns: columns,
      display_options: display_options
    }
  end

  @spec is_grouped?(__MODULE__.t()) :: boolean
  def is_grouped?(%__MODULE__{display_options: "grouped"}), do: true
  def is_grouped?(_), do: false

  @spec includes_fare_cards?(__MODULE__.t()) :: boolean
  def includes_fare_cards?(%__MODULE__{columns: columns}) do
    columns
    |> Enum.flat_map(& &1.paragraphs)
    |> Enum.any?(&is_a_fare_card?/1)
  end

  defp is_a_fare_card?(%FareCard{}), do: true
  defp is_a_fare_card?(_), do: false
end
