defmodule Content.Event do
  @moduledoc """
  Represents an "event" content type in the Drupal CMS.
  """

  import Phoenix.HTML, only: [raw: 1]
  import Content.Helpers, only: [field_value: 2, parse_body: 1, parse_iso_time: 1,
    handle_html: 1]

  defstruct [id: "", start_time: nil, end_time: nil, title: "", location: nil, street_address: nil,
    city: nil, state: nil, who: nil, body: raw(""), notes: raw(""), agenda: raw("")]

  @type t :: %__MODULE__{
    id: String.t,
    start_time: DateTime.t | nil,
    end_time: DateTime.t | nil,
    title: String.t,
    location: String.t | nil,
    street_address: String.t | nil,
    city: String.t | nil,
    state: String.t | nil,
    who: String.t | nil,
    body: Phoenix.HTML.safe,
    notes: Phoenix.HTML.safe,
    agenda: Phoenix.HTML.safe
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    %__MODULE__{
      id: field_value(data, "nid"),
      start_time: parse_iso_time(field_value(data, "field_start_time")),
      end_time: parse_iso_time(field_value(data, "field_end_time")),
      title: field_value(data, "title"),
      location: field_value(data, "field_location"),
      street_address: field_value(data, "field_street_address"),
      city: field_value(data, "field_city"),
      state: field_value(data, "field_state"),
      who: field_value(data, "field_who"),
      body: parse_body(data),
      notes: handle_html(field_value(data, "field_notes")),
      agenda: handle_html(field_value(data, "field_agenda"))
    }
  end
end
