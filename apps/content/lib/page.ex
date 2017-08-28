defmodule Content.Page do
  @moduledoc """
  Parses the api data to a struct, based on the api data's content type.
  """

  @type t :: Content.BasicPage.t | Content.LandingPage.t | Content.Redirect.t

  @doc """
  Expects parsed json from drupal CMS. Should be one item (not array of items)
  """
  @spec from_api(map) :: t
  def from_api(%{"type" => [%{"target_id" => "page"}]} = api_data) do
    Content.BasicPage.from_api(api_data)
  end
  def from_api(%{"type" => [%{"target_id" => "landing_page"}]} = api_data) do
    Content.LandingPage.from_api(api_data)
  end
  def from_api(%{"type" => [%{"target_id" => "redirect"}]} = api_data) do
    Content.Redirect.from_api(api_data)
  end
end
