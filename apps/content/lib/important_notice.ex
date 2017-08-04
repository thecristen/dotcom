defmodule Content.ImportantNotice do
  @moduledoc """

  Represents the "Important Notice" content type in the CMS. If there is an important
  notice it will get displayed as a banner atop the homepage.

  """

  import Content.Helpers, only: [field_value: 2, parse_link: 2]
  alias Content.Field.Image
  alias Content.Field.Link

  defstruct [blurb: "", link: %Link{}, thumb: nil]

  @type t :: %__MODULE__{
    blurb: String.t,
    link: Link.t | nil,
    thumb: Image.t | nil,
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    %__MODULE__{
      blurb: field_value(data, "field_in_blurb"),
      link: parse_link(data, "field_in_link"),
      thumb: parse_image(data["field_in_thumb"]),
    }
  end

  @spec parse_image([map]) :: Image.t | nil
  defp parse_image([%{} = api_image]), do: Image.from_api(api_image)
  defp parse_image(_), do: nil
end
