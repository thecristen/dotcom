defmodule Content.NewsEntry do
  @moduledoc """
  Represents a "news_entry" content type in the Drupal CMS.
  """
  @number_of_recent_news_suggestions 3

  import Content.Helpers, only: [field_value: 2, handle_html: 1, int_or_string_to_int: 1, parse_body: 1,
    parse_featured_image: 1, parse_updated_at: 1]

  defstruct [id: nil, title: "", body: Phoenix.HTML.raw(""), featured_image: nil, media_contact_name: "",
    media_contact_info: "", more_information: Phoenix.HTML.raw(""), updated_at: nil]

  @type t :: %__MODULE__{
    id: integer | nil,
    title: String.t,
    body: Phoenix.HTML.safe,
    featured_image: Content.Field.Image.t | nil,
    media_contact_name: String.t | nil,
    media_contact_info: String.t | nil,
    more_information: Phoenix.HTML.safe,
    updated_at: DateTime.t | nil
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    %__MODULE__{
      id: int_or_string_to_int(field_value(data, "nid")),
      title: field_value(data, "title"),
      body: parse_body(data),
      media_contact_name: field_value(data, "field_media_contact"),
      media_contact_info: field_value(data, "field_media_phone"),
      more_information: parse_more_information(data),
      updated_at: parse_updated_at(data),
      featured_image: parse_featured_image(data)
    }
  end

  defp parse_more_information(data) do
    data
    |> field_value("field_more_information")
    |> handle_html
  end

  def number_of_recent_news_suggestions do
    @number_of_recent_news_suggestions
  end
end
