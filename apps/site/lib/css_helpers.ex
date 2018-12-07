defmodule CSSHelpers do
  @moduledoc """
  Provides helpers for working with CSS

  Multiple pieces (SiteWeb and Components) use css,
  so this module provides helper functions to share between them.
  """

  @doc "Returns a css class: a string with hyphens."
  @spec atom_to_class(atom) :: String.t()
  def atom_to_class(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", "-")
  end
end
