defmodule Site.PageView do
  import Phoenix.HTML.Tag

  use Site.Web, :view

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
end
