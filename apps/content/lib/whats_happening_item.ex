defmodule Content.WhatsHappeningItem do
  import Content.Helpers, only: [field_value: 2, parse_link: 2, category: 1]

  defstruct [
    blurb: "",
    title: "",
    category: :unknown,
    link: nil,
    thumb: nil,
    thumb_2x: nil
  ]

  @type t :: %__MODULE__{
    blurb: String.t | nil,
    title: String.t | nil,
    category: Content.Helpers.category,
    link: Content.Field.Link.t | nil,
    thumb: Content.Field.Image.t,
    thumb_2x: Content.Field.Image.t | nil
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do

    {thumb, thumb_2x} = case parse_image(data["field_image"]) do
      %Content.Field.Image{} = image -> {image, nil}
      nil -> {parse_image(data["field_wh_thumb"]), parse_image(data["field_wh_thumb_2x"])}
    end

    %__MODULE__{
      blurb: field_value(data, "field_wh_blurb"),
      title: field_value(data, "title"),
      category: category(data),
      link: parse_link(data, "field_wh_link"),
      thumb: thumb,
      thumb_2x: thumb_2x
    }
  end

  @spec parse_image([map]) :: Content.Field.Image.t | nil
  defp parse_image([%{} = api_image]), do: Content.Field.Image.from_api(api_image)
  defp parse_image(_), do: nil
end
