defmodule Content.WhatsHappeningItem do
  import Content.Helpers, only: [field_value: 2, parse_link: 2]

  defstruct [blurb: "", link: nil, thumb: nil, thumb_2x: nil]

  @type t :: %__MODULE__{
    blurb: String.t,
    link: Content.Field.Link.t | nil,
    thumb: Content.Field.Image.t,
    thumb_2x: Content.Field.Image.t | nil
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    %__MODULE__{
      blurb: field_value(data, "field_wh_blurb"),
      link: parse_link(data, "field_wh_link"),
      thumb: parse_image(data["field_wh_thumb"]),
      thumb_2x: parse_image(data["field_wh_thumb_2x"])
    }
  end

  @spec parse_image([map]) :: Content.Field.Image.t | nil
  defp parse_image([%{} = api_image]), do: Content.Field.Image.from_api(api_image)
  defp parse_image(_), do: nil
end
