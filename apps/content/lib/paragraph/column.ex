defmodule Content.Paragraph.Column do
  @moduledoc """
  An individual column in a ColumnMulti set.
  """
  import Content.Helpers, only: [
    field_value: 2,
    handle_html: 1
  ]
  alias Content.Paragraph
  alias Phoenix.HTML

  defstruct [
    body: HTML.raw(""),
    paragraphs: []
  ]

  @type t :: %__MODULE__{
    body: HTML.safe,
    paragraphs: [Paragraph.t]
  }

  @spec from_api(map) :: t
  def from_api(data) do
    body =
      data
      |> field_value("field_column_body")
      |> handle_html

    paragraphs =
      data
      |> Map.get("field_content", [])
      |> Enum.map(&Paragraph.from_api/1)

    %__MODULE__{
      body: body,
      paragraphs: paragraphs
    }
  end
end
