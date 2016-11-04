defmodule Site.StaticPage do
  @moduledoc """
  Logic for pages which simply render a static template with no additional logic. Separated into its
  own module in order to allow use at compile time in other modules.
  """

  def static_pages do
    [:about, :getting_around]
  end

  def convert_path(path) do
    path
    |> Atom.to_string
    |> String.replace("_", "-")
  end
end
