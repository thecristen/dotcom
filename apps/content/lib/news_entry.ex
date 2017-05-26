defmodule Content.NewsEntry do
  @moduledoc """
  Represents a "news_entry" content type in the Drupal CMS.
  """
  @number_of_recent_news_suggestions 3

  import Content.Helpers, only: [
    field_value: 2, handle_html: 1, int_or_string_to_int: 1, parse_body: 1
  ]

  defstruct [
    id: nil,
    title: "",
    body: Phoenix.HTML.raw(""),
    media_contact: "",
    media_email: "",
    media_phone: "",
    more_information: Phoenix.HTML.raw(""),
    posted_on: nil,
    migration_id: nil
  ]

  @type t :: %__MODULE__{
    id: integer | nil,
    title: String.t,
    body: Phoenix.HTML.safe,
    media_contact: String.t | nil,
    media_email: String.t | nil,
    media_phone: String.t | nil,
    more_information: Phoenix.HTML.safe | nil,
    posted_on: Date.t | nil,
    migration_id: String.t | nil
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    %__MODULE__{
      id: int_or_string_to_int(field_value(data, "nid")),
      title: field_value(data, "title"),
      body: parse_body(data),
      media_contact: field_value(data, "field_media_contact"),
      media_email: field_value(data, "field_media_email"),
      media_phone: field_value(data, "field_media_phone"),
      more_information: parse_more_information(data),
      posted_on: parse_posted_date(data),
      migration_id: field_value(data, "field_migration_id")
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

  defp parse_posted_date(data) do
    data
    |> field_value("field_posted_on")
    |> Timex.parse!("{YYYY}-{0M}-{0D}")
    |> NaiveDateTime.to_date()
  end
end
