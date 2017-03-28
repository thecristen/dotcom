defmodule Content.NewsEntry do
  @moduledoc """
  Represents a "news_entry" content type in the Drupal CMS.
  """

  import Content.Helpers, only: [field_value: 2, handle_html: 1, parse_time: 1]

  defstruct [id: "", title: "", body: {:safe, ""}, featured_image: nil, media_contact_name: "",
    media_contact_info: "", more_information: "", updated_at: nil]

  @type t :: %__MODULE__{
    id: String.t,
    title: String.t,
    body: {:safe, String.t},
    featured_image: Content.Field.Image.t | nil,
    media_contact_name: String.t | nil,
    media_contact_info: String.t | nil,
    more_information: String.t | nil,
    updated_at: DateTime.t | nil
  }

  @spec from_api(map) :: __MODULE__.t
  def from_api(data) do
    %__MODULE__{
      id: field_value(data, "nid"),
      title: field_value(data, "title"),
      body: parse_body(data),
      media_contact_name: field_value(data, "field_media_contact"),
      media_contact_info: field_value(data, "field_media_phone"),
      more_information: field_value(data, "field_more_information"),
      updated_at: parse_updated_at(data),
      featured_image: parse_featured_image(data)
    }
  end

  defp parse_body(data) do
    data
    |> field_value("body")
    |> handle_html
  end

  defp parse_updated_at(data) do
    case field_value(data, "changed") do
      nil -> nil
      changed -> parse_time(changed)
    end
  end

  defp parse_featured_image(data) do
    if image = data["field_featured_image"] do
      Content.Field.Image.from_api(image)
    end
  end
end
