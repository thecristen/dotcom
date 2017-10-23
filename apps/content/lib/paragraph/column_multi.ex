defmodule Content.Paragraph.ColumnMulti do
  import Content.Helpers, only: [
    field_value: 2
  ]

  defstruct [columns: [], header: nil]

  @type t :: %__MODULE__{
    header: String.t | nil,    
    columns: [Content.Paragraph.Column.t]
  }

  @spec from_api(map) :: t
  def from_api(data) do
    columns =
      data
      |> Map.get("field_column", [])
      |> Enum.map(&Content.Paragraph.Column.from_api/1)

    %__MODULE__{
      header: field_value(data, "field_section_title"),
      columns: columns
    }
  end
end
