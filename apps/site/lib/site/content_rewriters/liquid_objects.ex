defmodule Site.ContentRewriters.LiquidObjects do
  @moduledoc """

  This module handles so-called "liquid objects": content appearing between
  {{ and }} in text. The wrapping braces should be removed and the text inside
  should be stripped before being given to this module.

  """

  import Phoenix.HTML, only: [raw: 1, safe_to_string: 1]
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import SiteWeb.PartialView.SvgIconWithCircle, only: [svg_icon_with_circle: 1]

  # "Plugins" for other Elixir apps
  import __MODULE__.Fare, only: [fare_request: 1]

  alias SiteWeb.PartialView.SvgIconWithCircle

  @spec replace(String.t) :: String.t
  def replace("fa " <> icon) do
    font_awesome_replace(icon)
  end
  def replace("mbta-circle-icon " <> icon) do
    mbta_svg_icon_replace(icon)
  end
  def replace("icon:" <> icon) do
    mbta_svg_icon_replace(icon)
  end
  def replace("app-badge " <> badge) do
    app_svg_badge_replace(badge)
  end
  def replace("fare:" <> tokens) do
    tokens |> fare_request() |> fare_replace(tokens)
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
  defp mbta_svg_icon("subway-red"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :red_line})
  defp mbta_svg_icon("subway-orange"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :orange_line})
  defp mbta_svg_icon("subway-blue"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :blue_line})
  defp mbta_svg_icon("subway-green"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :green_line})
  defp mbta_svg_icon("subway-green-b"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :green_line_b})
  defp mbta_svg_icon("subway-green-c"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :green_line_c})
  defp mbta_svg_icon("subway-green-d"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :green_line_d})
  defp mbta_svg_icon("subway-green-e"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :green_line_e})
  defp mbta_svg_icon("bus"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :bus})
  defp mbta_svg_icon("the-ride"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :the_ride})
  defp mbta_svg_icon("ferry"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :ferry})
  defp mbta_svg_icon("accessible"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :access})
  defp mbta_svg_icon("parking"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :parking_lot})
  defp mbta_svg_icon("t-logo"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :t_logo})
  defp mbta_svg_icon(unknown), do: raw(~s({{ unknown icon "#{unknown}" }}))

  defp app_svg_badge("apple"), do: SiteWeb.ViewHelpers.svg("badge-apple-store.svg")
  defp app_svg_badge("google"), do: SiteWeb.ViewHelpers.svg("badge-google-play.svg")
  defp app_svg_badge(unknown), do: raw(~s({{ unknown app badge "#{unknown}" }}))

  defp fare_replace({:ok, fare}, _), do: fare
  defp fare_replace({:error, {:invalid, token}}, input), do: "{{ fare:" <> replacement_error(input, token) <> " }}"
  defp fare_replace({:error, {_, details}}, input), do: "{{ " <> replacement_error(details) <> " fare:#{input} }}"

  defp replacement_error(text), do: safe_to_string(content_tag(:span, text, class: "text-danger"))
  defp replacement_error(text, target) do
    highlight = content_tag(:span, target, class: "text-danger")
    String.replace(text, target, safe_to_string(highlight))
  end
end
