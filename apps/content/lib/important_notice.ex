defmodule Content.ImportantNotice do
  @moduledoc """

  Represents the "Important Notice" content type in the CMS. If there is an important
  notice it will get displayed as a banner atop the homepage.

  """

  import Content.Helpers, only: [field_value: 2, parse_link_type: 2]

  defstruct [blurb: "", url: "", thumb: nil]

  @type t :: %__MODULE__{
    blurb: String.t,
    url: String.t,
    thumb: Content.Field.Image.t
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    %__MODULE__{
      blurb: field_value(data, "field_in_blurb"),
      url: parse_link_type(data, "field_in_link"),
      thumb: parse_image(data["field_in_thumb"]),
    }
  end

  @spec parse_image([map]) :: Content.Field.Image.t | nil
  defp parse_image([%{} = api_image]), do: Content.Field.Image.from_api(api_image)
  defp parse_image(_), do: nil
end
