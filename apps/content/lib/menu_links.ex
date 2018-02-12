defmodule Content.MenuLinks do
  @moduledoc """
  Represents a "Menu Links" content type in the Drupal CMS.
  """

  import Content.Helpers, only: [field_value: 2, handle_html: 1]

  defstruct [title: "", position: :bottom, blurb: Phoenix.HTML.raw(""), links: []]

  @type t :: %__MODULE__{
    title: String.t,
    position: :bottom | :top,
    blurb: Phoenix.HTML.safe,
    links: [Content.Field.Link.t]
  }

  @spec from_api(map) :: t
  def from_api(%{"type" => [%{"target_id" => "menu_links"}]} = data) do
    %__MODULE__{
      title: field_value(data, "title"),
      position: String.to_existing_atom(field_value(data, "field_menu_position")),
      blurb: parse_blurb(data),
      links: Enum.map(data["field_links"], & Content.Field.Link.from_api(&1))
    }
  end

  @spec parse_blurb(map) :: Phoenix.HTML.Safe.t
  defp parse_blurb(data) do
    data
    |> field_value("field_blurb")
    |> handle_html
  end
end
