defmodule Site.NewsEntryView do
  use Site.Web, :view
  import Site.TimeHelpers, only: [format_date: 1]
  import Site.ContentHelpers, only: [content: 1]

  def render_recent_news?(recent_news) do
    Enum.count(recent_news) == 3
  end
end
