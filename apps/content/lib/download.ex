defmodule Content.Download do
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
  @spec from_api(any) :: __MODULE__.t | nil
  def from_api(%{"description" => description, "url" => url, "target_type" => type}) do
    %Content.Download{
      description: description,
      url: url,
      type: type
    }
  end
  def from_api(_) do
    nil
  end
end
