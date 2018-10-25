defmodule SiteWeb.PageView do
  import Phoenix.HTML.Tag
  alias Content.Banner

  use SiteWeb, :view

  def shortcut_icons do
    rows = for row <- [[:stations, :subway, :bus], [:commuter_rail, :ferry, :the_ride]] do
      content_tag(:div, Enum.map(row, &shortcut_icon/1), class: "m-homepage__shortcut-row")
    end
    content_tag(:div, rows, class: "m-homepage__shortcuts")
  end

  @spec shortcut_icon(atom) :: Phoenix.HTML.Safe.t
  defp shortcut_icon(id) do
    content_tag(:a, [
      id |> shortcut_svg_name() |> svg(),
      content_tag(:div, shortcut_text(id), class: "m-homepage__shortcut-text"),
    ], href: shortcut_link(id), class: "m-homepage__shortcut")
  end

  @spec shortcut_link(atom) :: String.t
  defp shortcut_link(:stations), do: stop_path(SiteWeb.Endpoint, :index)
  defp shortcut_link(:the_ride), do: cms_static_page_path(SiteWeb.Endpoint, "/accessibility/the-ride")
  defp shortcut_link(:nearby), do: transit_near_me_path(SiteWeb.Endpoint, :index)
  defp shortcut_link(mode), do: schedule_path(SiteWeb.Endpoint, :show, mode)

  @spec shortcut_text(atom) :: [Phoenix.HTML.Safe.t]
  defp shortcut_text(:stations) do
    [
      "Stations",
      content_tag(:span, [" &", tag(:br), "Stops"], class: "hidden-md-down")
    ]
  end
  defp shortcut_text(:the_ride) do
    [
      content_tag(:span, [
        content_tag(:span, [
          "The",
          tag(:br),
        ], class: "hidden-md-down"),
        "RIDE"
      ]),
    ]
  end
  defp shortcut_text(:commuter_rail) do
    [
      content_tag(:span, "Commuter ", class: "hidden-md-down"),
      tag(:br, class: "hidden-md-down"),
      "Rail",
      content_tag(:span, [raw("&nbsp;"), "Lines"], class: "hidden-md-down")
    ]
  end
  defp shortcut_text(:subway) do
    [
      "Subway",
      content_tag(:span, [tag(:br), "Lines"], class: "hidden-md-down")
    ]
  end
  defp shortcut_text(mode) do
    [
      mode_name(mode),
      content_tag(:span, [tag(:br), "Routes"], class: "hidden-md-down")
    ]
  end

  defp shortcut_svg_name(:stations), do: "icon-circle-t-default.svg"
  defp shortcut_svg_name(:the_ride), do: "icon-the-ride-default.svg"
  defp shortcut_svg_name(:commuter_rail), do: shortcut_svg_name(:"commuter-rail")
  defp shortcut_svg_name(mode), do: "icon-mode-#{mode}-default.svg"

  def schedule_separator do
    content_tag :span, "|", aria_hidden: "true", class: "schedule-separator"
  end

  @spec whats_happening_image(Content.WhatsHappeningItem.t) :: Phoenix.HTML.safe
  def whats_happening_image(%Content.WhatsHappeningItem{thumb: thumb, thumb_2x: nil}) do
    img_tag(thumb.url, alt: thumb.alt)
  end
  def whats_happening_image(%Content.WhatsHappeningItem{thumb: thumb, thumb_2x: thumb_2x}) do
    img_tag(thumb.url, alt: thumb.alt, sizes: "(max-width: 543px) 100vw, 33vw", srcset: "#{thumb.url} 304w, #{thumb_2x.url} 608w")
  end

  @spec render_news_entries(Plug.Conn.t) :: Phoenix.HTML.Safe.t
  def render_news_entries(conn) do
    content_tag(:div,
      conn.assigns
      |> Map.get(:news)
      |> Enum.split(2)
      |> Tuple.to_list()
      |> Enum.with_index()
      |> Enum.map(&do_render_news_entries(&1, conn)),
    class: "row")
  end

  @spec do_render_news_entries({[Content.NewsEntry.t], 0 | 1}, Plug.Conn.t) :: Phoenix.HTML.Safe.t
  defp do_render_news_entries({entries, idx}, conn) when idx in [0, 1] do
    size = if idx == 0, do: :large, else: :small

    content_tag(
      :div,
      Enum.map(entries, & render_news_entry(&1, size, conn)),
      class: "col-md-6"
    )
  end

  @spec render_news_entry(Content.NewsEntry.t, :large | :small, Plug.Conn.t) :: Phoenix.HTML.Safe.t
  defp render_news_entry(%{utm_url: utm_url} = entry, size, conn) do
    link([
      render_news_date(entry, size),
      content_tag(:div, entry.title, class: "c-news-entry__title c-news-entry__title--#{size}")
    ], to: cms_static_page_path(conn, utm_url), class: "c-news-entry c-news-entry--#{size}")
  end

  @spec render_news_date(Content.NewsEntry.t, :large | :small) :: Phoenix.HTML.Safe.t
  defp render_news_date(entry, size) do
    content_tag(:div, [
      content_tag(
        :span,
        Timex.format!(entry.posted_on, "{Mshort}"),
        class: "c-news-entry__month c-news-entry__month--#{size}"
      ),
      content_tag(
        :span,
        Timex.format!(entry.posted_on, "{0D}"),
        class: "c-news-entry__day--#{size}"
      )
    ], class: "c-news-entry__date c-news-entry__date--#{size} u-small-caps")
  end

  @spec banner_content_class(Banner.t) :: String.t
  defp banner_content_class(%Banner{} = banner) do
    Enum.join([
      "m-banner__content",
      "m-banner__content--" <> CSSHelpers.atom_to_class(banner.banner_type),
      "m-banner__content--" <> CSSHelpers.atom_to_class(banner.text_position)
      | banner_bg_class(banner)
    ], " ")
  end

  @spec banner_bg_class(Banner.t) :: [String.t]
  defp banner_bg_class(%Banner{banner_type: :important}), do: []
  defp banner_bg_class(%Banner{mode: mode}), do: ["u-bg--" <> CSSHelpers.atom_to_class(mode)]

  @spec banner_cta(Banner.t) :: Phoenix.HTML.Safe.t
  defp banner_cta(%Banner{banner_type: :important, link: %{title: title}}) do
    content_tag(:span, title, class: "m-banner__cta")
  end
  defp banner_cta(%Banner{}) do
    ""
  end
end
