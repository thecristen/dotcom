defmodule Content.ProjectUpdate do
  @moduledoc """
  Represents a "project_update" type in the Drupal CMS.
  """

  import Content.Helpers, only: [field_value: 2, handle_html: 1, parse_time: 1]

  defstruct [id: "", body: {:safe, ""}, title: "", featured_image: nil, photo_gallery: [],
    updated_at: nil, status: "", downloads: []]

  @type t :: %__MODULE__{
    id: String.t,
    body: {:safe, String.t},
    title: String.t,
    featured_image: Content.Image.t | nil,
    photo_gallery: [Content.Image.t],
    updated_at: DateTime.t | nil,
    status: String.t | nil,
    downloads: [Content.Download.t]
  }

  @spec from_api(map) :: __MODULE__.t
  def from_api(data) do
    %__MODULE__{
      id: field_value(data, "nid"),
      body: parse_body(data),
      title: field_value(data, "title"),
      featured_image: parse_featured_image(data),
      photo_gallery: parse_photo_gallery(data),
      updated_at: parse_updated_at(data),
      status: field_value(data, "field_status"),
      downloads: parse_downloads(data)
    }
  end

  defp parse_body(data) do
    data
    |> field_value("body")
    |> handle_html
  end

  defp parse_featured_image(data) do
    if image = data["field_featured_image"] do
      Content.Image.from_api(image)
    end
  end

  defp parse_photo_gallery(data) do
    case data["field_photo_gallery"] do
      nil -> []
      photos -> Enum.map(photos, &Content.Image.from_api/1)
    end
  end

  defp parse_updated_at(data) do
    case field_value(data, "changed") do
      nil -> nil
      changed -> parse_time(changed)
    end
  end

  defp parse_downloads(data) do
    case data["field_downloads"] do
      nil -> []
      downloads -> Enum.map(downloads, &Content.Download.from_api/1)
    end
  end
end
