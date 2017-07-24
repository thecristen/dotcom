defmodule Site.ContentView do
  use Site.Web, :view
  import Site.EventView, only: [event_duration: 2]

  defdelegate fa_icon_for_file_type(mime), to: Site.FontAwesomeHelpers

  @spec render_paragraph(Content.Paragraph.t) :: Phoenix.HTML.safe
  def render_paragraph(%Content.Paragraph.CustomHTML{} = para) do
    para.body
  end
  def render_paragraph(%Content.Paragraph.TitleCardSet{} = para) do
    render "_title_card_set.html", paragraph: para
  end
  def render_paragraph(%Content.Paragraph.UpcomingBoardMeetings{} = para) do
    render "_upcoming_board_meetings.html", paragraph: para
  end
  def render_paragraph(%Content.Paragraph.PeopleGrid{} = para) do
    render "_people_grid.html", paragraph: para
  end
  def render_paragraph(%Content.Paragraph.FilesGrid{} = para) do
    render "_files_grid.html", paragraph: para
  end
  def render_paragraph(%Content.Paragraph.Unknown{} = para) do
    render "_unknown.html", paragraph: para
  end

  def file_description(%Content.Field.File{description: desc}) when not is_nil(desc) and desc != "" do
    desc
  end
  def file_description(%Content.Field.File{url: url}) do
    url |> Path.basename |> URI.decode
  end
end
