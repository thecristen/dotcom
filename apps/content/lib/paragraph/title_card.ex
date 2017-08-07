defmodule Content.Paragraph.TitleCard do
  import Content.Helpers, only: [
    field_value: 2,
    handle_html: 1,
    parse_link: 2
  ]

  defstruct [body: Phoenix.HTML.raw(""), link: nil, title: ""]

  @type t :: %__MODULE__{
    body: Phoenix.HTML.safe,
    link: Content.Field.Link.t | nil,
    title: String.t
  }

  @spec from_api(map) :: t
  def from_api(data) do
    %__MODULE__{
      body: data |> field_value("field_title_card_body") |> handle_html,
      link: parse_link(data, "field_title_card_link"),
      title: field_value(data, "field_title_card_title"),
    }
  end
end
