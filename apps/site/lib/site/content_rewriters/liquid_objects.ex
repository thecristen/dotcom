defmodule Site.ContentRewriters.LiquidObjects do
  @moduledoc """

  This module handles so-called "liquid objects": content appearing between
  {{ and }} in text. The wrapping braces should be removed and the text inside
  should be stripped before being given to this module.

  """

  import Phoenix.HTML, only: [raw: 1, safe_to_string: 1]
  import SiteWeb.PartialView.SvgIconWithCircle, only: [svg_icon_with_circle: 1]

  alias SiteWeb.PartialView.SvgIconWithCircle

  @available_fare_replacements [
    "subway:charlie_card",
    "subway:cash",
    "bus:charlie_card",
    "bus:cash",
  ]

  @doc "Replace fa- prefixed objects with corresponding fa() call"
  @spec replace(String.t) :: String.t
  def replace("fa " <> icon) do
    font_awesome_replace(icon)
  end
  def replace("mbta-circle-icon " <> icon) do
    mbta_svg_icon_replace(icon)
  end
  def replace("app-badge " <> badge) do
    app_svg_badge_replace(badge)
  end
  def replace("fare:" <> filters) when filters in @available_fare_replacements do
    filters
    |> fare_filter
    |> Fares.Repo.all
    |> List.first
    |> Fares.Format.price
  end
  def replace(unmatched) do
    "{{ #{unmatched} }}"
  end

  defp font_awesome_replace(icon) do
    icon
    |> get_arg
    |> SiteWeb.ViewHelpers.fa
    |> safe_to_string
  end

  defp mbta_svg_icon_replace(icon) do
    icon
    |> get_arg
    |> mbta_svg_icon
    |> safe_to_string
  end

  defp app_svg_badge_replace(badge) do
    badge
    |> get_arg
    |> app_svg_badge
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
  defp mbta_svg_icon("t-logo"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :t_logo})
  defp mbta_svg_icon(unknown), do: raw(~s({{ mbta-circle-icon "#{unknown}" }}))

  defp app_svg_badge("apple"), do: SiteWeb.ViewHelpers.svg("badge-apple-store.svg")
  defp app_svg_badge("google"), do: SiteWeb.ViewHelpers.svg("badge-google-play.svg")
  defp app_svg_badge(unknown), do: raw(~s({{ app-badge "#{unknown}" }}))

  defp fare_filter("subway:charlie_card"), do: [mode: :subway, includes_media: :charlie_card, duration: :single_trip]
  defp fare_filter("subway:cash"), do: [mode: :subway, includes_media: :cash, duration: :single_trip]
  defp fare_filter("bus:charlie_card"), do: [name: :local_bus, includes_media: :charlie_card, duration: :single_trip]
  defp fare_filter("bus:cash"), do: [name: :local_bus, includes_media: :cash, duration: :single_trip]
end
