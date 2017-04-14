defmodule Site.ContentRewriters.LiquidObjects do
  @moduledoc """

  This module handles so-called "liquid objects": content appearing between
  {{ and }} in text. The wrapping braces should be removed and the text inside
  should be stripped before being given to this module.

  """

  @doc "Replace fa- prefixed objects with corresponding fa() call"
  @spec replace(String.t) :: String.t
  def replace("fa " <> icon) do
    font_awesome_replace(icon)
  end
  def replace(unmatched) do
    "{{ #{unmatched} }}"
  end

  defp font_awesome_replace(icon) do
    icon
    |> String.replace("\"", "")
    |> String.strip
    |> Site.ViewHelpers.fa
    |> Phoenix.HTML.safe_to_string
  end
end
