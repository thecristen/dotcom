defmodule Site.StationView do
  use Site.Web, :view

  def google_api_key do
    Application.get_env(:site, __MODULE__)[:google_api_key]
  end

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
    content_tag(:a, value, href: "mailto:#{value}")
  end

  def optional_link(value, "") do
    value
  end
  def optional_link(value, href) do
    href_value = case href do
                   <<"http://", _::binary>> -> href
                   <<"https://", _::binary>> -> href
                   _ -> "http://" <> href
                 end
    content_tag(:a, value, href: href_value)
  end
end
