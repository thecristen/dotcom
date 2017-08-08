defmodule Content.BasicPage do
  @moduledoc """
  Represents a basic "page" type in the Drupal CMS.
  """

  import Content.Helpers, only: [
    field_value: 2,
    int_or_string_to_int: 1,
    parse_body: 1,
    parse_paragraphs: 1
  ]

  defstruct [
    body: Phoenix.HTML.raw(""),
    id: nil,
    paragraphs: [],
    sidebar_menu: nil,
    title: "",
    breadcrumbs: []
  ]

  @type t :: %__MODULE__{
    id: integer | nil,
    title: String.t,
    body: Phoenix.HTML.safe,
    paragraphs: [Content.Paragraph.t],
    sidebar_menu: Content.MenuLinks.t | nil,
    breadcrumbs: [Util.Breadcrumb.t]
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    %__MODULE__{
      id: int_or_string_to_int(field_value(data, "nid")),
      title: field_value(data, "title") || "",
      body: parse_body(data),
      paragraphs: parse_paragraphs(data),
      sidebar_menu: parse_menu_links(data),
      breadcrumbs: Content.Breadcrumbs.build(data)
    }
  end

  @spec parse_menu_links(map) :: Content.MenuLinks.t | nil
  defp parse_menu_links(%{"field_sidebar_menu" => [menu_links_data]}) do
    Content.MenuLinks.from_api(menu_links_data)
  end
  defp parse_menu_links(_) do
    nil
  end
end
