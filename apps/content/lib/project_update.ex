defmodule Content.ProjectUpdate do
  @moduledoc """
  Represents the Project Update content type in the CMS.
  """

  import Content.Helpers, only: [
    field_value: 2,
    int_or_string_to_int: 1,
    parse_body: 1,
    parse_date: 2,
    parse_images: 2,
    path_alias: 1
  ]

  @enforce_keys [:id, :project_id]
  defstruct [
    :id,
    :project_id,
    :path_alias,
    project_url: "",
    body: Phoenix.HTML.raw(""),
    photo_gallery: [],
    posted_on: "",
    teaser: "",
    title: "",
  ]

  @type t :: %__MODULE__{
    id: integer,
    body: Phoenix.HTML.safe,
    photo_gallery: [Content.Field.Image.t],
    posted_on: Date.t,
    project_id: integer,
    project_url: String.t,
    path_alias: String.t | nil,
    teaser: String.t,
    title: String.t,
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    {project_id, project_alias} = parse_project(data)
    %__MODULE__{
      id: int_or_string_to_int(field_value(data, "nid")),
      body: parse_body(data),
      photo_gallery: parse_images(data, "field_photo_gallery"),
      posted_on: parse_date(data, "field_posted_on"),
      project_id: project_id,
      project_url: project_alias,
      teaser: field_value(data, "field_teaser"),
      title: field_value(data, "title"),
      path_alias: path_alias(data)
    }
  end

  defp parse_project(%{"field_project" => [%{"target_id" => id, "url" => url}]}), do: {id, url}
  defp parse_project(%{"field_project" => [%{"target_id" => id}]}), do: {id, ""}
end
