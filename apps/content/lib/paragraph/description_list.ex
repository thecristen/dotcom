defmodule Content.Paragraph.DescriptionList do
  @moduledoc """
  A description list element (optionally including a header) from the CMS.
  """

  alias Content.Paragraph.{ColumnMultiHeader, Description}

  defstruct header: nil,
            descriptions: []

  @type t :: %__MODULE__{
          header: ColumnMultiHeader.t() | nil,
          descriptions: [Description.t()]
        }

  @spec from_api(map) :: t
  def from_api(data) do
    header =
      data
      |> Map.get("field_multi_column_header", [])
      |> Enum.map(&ColumnMultiHeader.from_api/1)
      # There is only ever 1 header element
      |> List.first()

    descriptions =
      data
      |> Map.get("field_definition", [])
      |> Enum.map(&Description.from_api/1)

    %__MODULE__{
      header: header,
      descriptions: descriptions
    }
  end
end
