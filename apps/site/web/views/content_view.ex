defmodule Site.ContentView do
  use Site.Web, :view

  @spec render_paragraph(Content.Paragraph.t) :: Phoenix.HTML.safe
  def render_paragraph(%Content.Paragraph.CustomHTML{} = para) do
    para.body
  end
  def render_paragraph(%Content.Paragraph.TitleCardSet{} = para) do
    render "_title_card_set.html", paragraph: para
  end
end
