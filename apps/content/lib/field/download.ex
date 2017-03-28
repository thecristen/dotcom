defmodule Content.Field.Download do
  @moduledoc """
  Represents a downloadable file field in the Drupal CMS. This field is embedded
  in other drupal content types, like Content.ProjectUpdate.
  """

  defstruct [description: "", url: "", type: ""]

  @type t :: %__MODULE__{
    description: String.t,
    url: String.t,
    type: String.t
  }

  # TODO: do we need to rewrite these urls to use the CDN as well?
  @spec from_api(map) :: t
  def from_api(%{"description" => description, "url" => url, "target_type" => type}) do
    %__MODULE__{
      description: description,
      url: url,
      type: type
    }
  end
end
