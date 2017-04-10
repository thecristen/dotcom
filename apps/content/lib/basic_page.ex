defmodule Content.BasicPage do
  @moduledoc """
  Represents a basic "page" type in the Drupal CMS.
  """

  import Content.Helpers, only: [field_value: 2, int_or_string_to_int: 1, parse_body: 1]

  defstruct [id: nil, title: "", body: Phoenix.HTML.raw("")]

  @type t :: %__MODULE__{
    id: integer | nil,
    title: String.t,
    body: Phoenix.HTML.safe
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    %__MODULE__{
      id: int_or_string_to_int(field_value(data, "nid")),
      title: field_value(data, "title") || "",
      body: parse_body(data)
    }
  end
end
