defmodule SiteWeb.ProjectView do
  @moduledoc """
  Project page-related view helpers.
  """
  use SiteWeb, :view
  alias Content.{Field.Image, ProjectUpdate}

  @doc """
  Reports whether the project update includes images in its photo gallery.
  """
  @spec includes_photos?(ProjectUpdate.t()) :: boolean
  def includes_photos?(%ProjectUpdate{photo_gallery: photo_gallery}),
    do: length(photo_gallery) > 0

  @doc """
  Returns the first photo from its photo gallery.
  """
  @spec first_photo(ProjectUpdate.t()) :: Image.t()
  def first_photo(%ProjectUpdate{photo_gallery: photo_gallery}), do: List.first(photo_gallery)
end
