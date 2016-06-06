defmodule Site.PageView do
  use Site.Web, :view

  def clean_route_name(name) do
    name
    |> String.replace_suffix(" Line", "")
    |> String.replace("/", "/​") # slash replaced with a slash with a ZERO
                                # WIDTH SPACE afer
  end
end
