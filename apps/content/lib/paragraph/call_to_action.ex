defmodule Content.Paragraph.CallToAction do
  @moduledoc """
  Represents a Call To Action paragraph type in the Drupal CMS.
  """

  import Content.Helpers, only: [
    parse_link: 2,
  ]

  defstruct [link: nil]

  @type t :: %__MODULE__{
    link: Content.Field.Link.t | nil,
  }

  @spec from_api(map) :: t
  def from_api(data) do
    %__MODULE__{
      link: parse_link(data, "field_call_to_action_link"),
    }
  end
end
