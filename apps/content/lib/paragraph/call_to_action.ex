defmodule Content.Paragraph.CallToAction do
  @moduledoc """
  Represents a Call To Action paragraph type in the Drupal CMS.
  """

  import Content.Helpers, only: [
    parse_link_type: 2,
    parse_link_text: 2
  ]

  defstruct [text: "", url: ""]

  @type t :: %__MODULE__{
    text: String.t,
    url: String.t
  }

  @spec from_api(map) :: t
  def from_api(data) do
    %__MODULE__{
      text: parse_link_text(data, "field_call_to_action_link"),
      url: parse_link_type(data, "field_call_to_action_link")
    }
  end
end
