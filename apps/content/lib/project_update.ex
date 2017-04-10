defmodule Content.ProjectUpdate do
  @moduledoc """
  Represents a "project_update" type in the Drupal CMS.
  """

  import Content.Helpers, only: [field_value: 2, int_or_string_to_int: 1, parse_body: 1, parse_featured_image: 1,
    parse_updated_at: 1]

  defstruct [id: nil, body: Phoenix.HTML.raw(""), title: "", featured_image: nil, photo_gallery: [],
    updated_at: nil, status: "", downloads: []]

  @type t :: %__MODULE__{
    id: integer | nil,
    body: Phoenix.HTML.safe,
    title: String.t,
    featured_image: Content.Field.Image.t | nil,
    photo_gallery: [Content.Field.Image.t],
    updated_at: DateTime.t | nil,
    status: String.t | nil,
    downloads: [Content.Field.Download.t]
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    %__MODULE__{
      id: int_or_string_to_int(field_value(data, "nid")),
      body: parse_body(data),
      title: field_value(data, "title"),
      featured_image: parse_featured_image(data),
      photo_gallery: parse_photo_gallery(data),
      updated_at: parse_updated_at(data),
      status: field_value(data, "field_status"),
      downloads: parse_downloads(data)
    }
  end

  defp parse_photo_gallery(data) do
    data["field_photo_gallery"]
    |> Enum.map(&Content.Field.Image.from_api/1)
  end

  defp parse_downloads(data) do
    data["field_downloads"]
    |> Enum.map(&Content.Field.Download.from_api/1)
  end
end
