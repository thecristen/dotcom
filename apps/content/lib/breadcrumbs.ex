defmodule Content.Breadcrumbs do
  @moduledoc """
  Maps CMS breadcrumbs to a breadcrumb struct.
  """

  @spec build(map) :: [Util.Breadcrumb.t]
  def build(%{"breadcrumbs" => breadcrumbs}) do
    Enum.map(breadcrumbs, fn(crumb) ->
      Util.Breadcrumb.build(crumb["text"], crumb["uri"])
    end)
  end
  def build(_missing_breadcrumbs) do
    []
  end
end
