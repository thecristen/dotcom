defmodule Content.Event do
  @moduledoc """
  Represents an "event" content type in the Drupal CMS.
  """

  import Phoenix.HTML, only: [raw: 1]
  import Content.Helpers, only: [field_value: 2, int_or_string_to_int: 1, parse_body: 1, parse_iso_datetime: 1,
    handle_html: 1, parse_files: 2]

  defstruct [
    id: nil, start_time: nil, end_time: nil, title: "", location: nil, street_address: nil,
    city: nil, state: nil, who: nil, body: raw(""), notes: raw(""), agenda: raw(""),
    meeting_id: nil, imported_address: nil, files: [], agenda_file: nil, minutes_file: nil
  ]

  @type t :: %__MODULE__{
    id: integer | nil,
    start_time: DateTime.t | nil,
    end_time: DateTime.t | nil,
    title: Phoenix.HTML.safe,
    location: String.t | nil,
    street_address: String.t | nil,
    city: String.t | nil,
    state: String.t | nil,
    who: String.t | nil,
    body: Phoenix.HTML.safe,
    notes: Phoenix.HTML.safe,
    agenda: Phoenix.HTML.safe,
    meeting_id: String.t | nil,
    imported_address: Phoenix.HTML.safe,
    files: [Content.Field.File.t],
    agenda_file: Content.Field.File.t | nil,
    minutes_file: Content.Field.File.t | nil
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    %__MODULE__{
      id: int_or_string_to_int(field_value(data, "nid")),
      start_time: parse_iso_datetime(field_value(data, "field_start_time")),
      end_time: parse_iso_datetime(field_value(data, "field_end_time")),
      title: handle_html(field_value(data, "title")),
      location: field_value(data, "field_location"),
      street_address: field_value(data, "field_street_address"),
      city: field_value(data, "field_city"),
      state: field_value(data, "field_state"),
      who: field_value(data, "field_who"),
      body: parse_body(data),
      notes: handle_html(field_value(data, "field_notes")),
      agenda: handle_html(field_value(data, "field_agenda")),
      imported_address: handle_html(field_value(data, "field_imported_address")),
      meeting_id: field_value(data, "field_meeting_id"),
      files: parse_files(data, "field_other_files"),
      agenda_file: parse_files(data, "field_agenda_file") |> List.first,
      minutes_file: parse_files(data, "field_minutes_file") |> List.first
    }
  end
end
