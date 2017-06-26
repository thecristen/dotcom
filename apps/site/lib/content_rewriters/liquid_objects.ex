defmodule Site.ContentRewriters.LiquidObjects do
  @moduledoc """

  This module handles so-called "liquid objects": content appearing between
  {{ and }} in text. The wrapping braces should be removed and the text inside
  should be stripped before being given to this module.

  """

  import Phoenix.HTML, only: [raw: 1, safe_to_string: 1]
  import Site.ContentView, only: [svg_icon_with_circle: 1]

  alias Site.Components.Icons.SvgIconWithCircle

  @doc "Replace fa- prefixed objects with corresponding fa() call"
  @spec replace(String.t) :: String.t
  def replace("fa " <> icon) do
    font_awesome_replace(icon)
  end
  def replace("mbta-circle-icon " <> icon) do
    mbta_svg_icon_replace(icon)
  end
  def replace(unmatched) do
    "{{ #{unmatched} }}"
  end

  defp font_awesome_replace(icon) do
    icon
    |> get_arg
    |> Site.ViewHelpers.fa
    |> safe_to_string
  end

  defp mbta_svg_icon_replace(icon) do
    icon
    |> get_arg
    |> mbta_svg_icon
    |> safe_to_string
  end

  defp get_arg(str) do
    str
    |> String.replace("\"", "")
    |> String.trim
  end

  defp mbta_svg_icon("commuter-rail"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :commuter_rail})
  defp mbta_svg_icon("subway"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :subway})
  defp mbta_svg_icon("bus"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :bus})
  defp mbta_svg_icon("ferry"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :ferry})
  defp mbta_svg_icon("t-logo"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :t_logo, class: "icon-boring"})
  defp mbta_svg_icon(unknown), do: raw(~s({{ mbta-circle-icon "#{unknown}" }}))
end
