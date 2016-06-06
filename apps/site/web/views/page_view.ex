defmodule Site.PageView do
  use Site.Web, :view

  def clean_route_name(name) do
    name
    |> String.replace_suffix(" Line", "")
  end
end
