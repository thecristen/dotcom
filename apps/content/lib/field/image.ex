defmodule Content.Field.Image do
  @moduledoc """
  Represents an image field in the Drupal CMS. This image field is embedded
  in other content types like Content.NewsEntry.
  """

  defstruct [url: "", alt: ""]

  @type t :: %__MODULE__{
    url: String.t,
    alt: String.t
  }

  # TODO: do we need to rewrite these urls to use the CDN as well?
  @spec from_api(map | [map]) :: t
  def from_api([%{"alt" => alt, "url" => url}]) do
    %__MODULE__{alt: alt, url: url}
  end
  def from_api(%{"alt" => alt, "url" => url}) do
    %__MODULE__{alt: alt, url: url}
  end
end
