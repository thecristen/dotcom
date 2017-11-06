defmodule Content.Paragraph.Column do
  import Content.Helpers, only: [
    field_value: 2,
    handle_html: 1
  ]

  defstruct [body: Phoenix.HTML.raw("")]

  @type t :: %__MODULE__{
    body: Phoenix.HTML.safe
  }

  @spec from_api(map) :: t
  def from_api(data) do
    %__MODULE__{
      body: data |> field_value("field_column_body") |> handle_html
    }
  end
end
