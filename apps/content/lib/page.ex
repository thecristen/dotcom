defmodule Content.Page do
  @moduledoc """
  Helper functions for working with the "page" types from the CMS:
  Content.BasicPage and Content.ProjectUpdate.
  """

  @type t :: Content.BasicPage.t | Content.ProjectUpdate

  @doc """
  Expects parsed json from drupal CMS. Should be one item (not array of items)
  """
  @spec from_api(map) :: t
  def from_api(%{"type" => [%{"target_id" => "page"}]} = api_data) do
    Content.BasicPage.from_api(api_data)
  end
  def from_api(%{"type" => [%{"target_id" => "project_update"}]} = api_data) do
    Content.ProjectUpdate.from_api(api_data)
  end
end
