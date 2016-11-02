defmodule Site.StationView do
  use Site.Web, :view

  def type_mode(:bus), do: "bus_subway"
  def type_mode(:subway), do: "bus_subway"
  def type_mode(type), do: type

  def location(station) do
    case station.latitude do
      nil -> URI.encode(station.address, &URI.char_unreserved?/1)
      _ -> "#{station.latitude},#{station.longitude}"
    end
  end

  def pretty_accessibility("tty_phone"), do: "TTY Phone"
  def pretty_accessibility("escalator_both"), do: "Escalator (Both)"
  def pretty_accessibility(accessibility) do
    accessibility
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  def optional_li(""), do: ""
  def optional_li(nil), do: ""
  def optional_li(value) do
    content_tag :li, value
  end

  def phone("") do
    ""
  end
  def phone(value) do
    content_tag(:a, value, href: "tel:#{value}")
  end

  def email("") do
    ""
  end
  def email(value) do
    display_value = value
    |> String.replace("@", "@\u200B")
    content_tag(:a, display_value, href: "mailto:#{value}")
  end

  def optional_link("", _) do
    nil
  end
  def optional_link(href, value) do
    href_value = case href do
                   <<"http://", _::binary>> -> href
                   <<"https://", _::binary>> -> href
                   _ -> "http://" <> href
                 end
    content_tag(:a, value, href: href_value, target: "_blank")
  end

  def sort_parking_spots(spots) do
    spots
    |> Enum.sort_by(fn %{type: type} ->
      case type do
        "basic" -> 0
        "accessible" -> 1
        _ -> 2
      end
    end)
  end
  def parking_type("basic"), do: "Parking"
  def parking_type(type), do: type |> String.capitalize
end
