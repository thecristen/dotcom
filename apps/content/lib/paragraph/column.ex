defmodule Content.Paragraph.Column do
  import Content.Helpers, only: [
    field_value: 2,
    handle_html: 1
  ]

  defstruct [body: Phoenix.HTML.raw(""), title: ""]

  @type t :: %__MODULE__{
    title: String.t,
    body: Phoenix.HTML.safe
  }

  @spec from_api(map) :: t
  def from_api(data) do
    %__MODULE__{
      title: field_value(data, "field_column_header"),
      body: data |> field_value("field_column_body") |> handle_html
    }
  end
end
