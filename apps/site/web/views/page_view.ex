defmodule Site.PageView do
  import Phoenix.HTML.Tag

  use Site.Web, :view

  def schedule_separator do
    content_tag :span, "|", aria_hidden: "true"
  end
end
