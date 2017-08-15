defmodule Site.ContentView do
  use Site.Web, :view
  import Site.TimeHelpers
  alias Site.ContentRewriter

  defdelegate fa_icon_for_file_type(mime), to: Site.FontAwesomeHelpers

  @spec render_paragraph(Content.Paragraph.t) :: Phoenix.HTML.safe
  def render_paragraph(%Content.Paragraph.CustomHTML{} = para) do
    ContentRewriter.rewrite(para.body)
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
  def render_paragraph(%Content.Paragraph.CallToAction{} = para) do
    render "_call_to_action.html", paragraph: para
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

  @doc "Nicely renders the duration of an event, given two DateTimes."
  @spec render_duration(NaiveDateTime.t | DateTime.t, NaiveDateTime.t | DateTime.t | nil) :: String.t
  def render_duration(start_time, end_time)
  def render_duration(start_time, nil) do
    start_time
    |> maybe_shift_timezone
    |> do_render_duration(nil)
  end
  def render_duration(start_time, end_time) do
    start_time
    |> maybe_shift_timezone
    |> do_render_duration(maybe_shift_timezone(end_time))
  end

  defp maybe_shift_timezone(%NaiveDateTime{} = time) do
    time
  end
  defp maybe_shift_timezone(%DateTime{} = time) do
    Util.to_local_time(time)
  end

  defp do_render_duration(start_time, nil) do
    "#{format_date(start_time)} at #{format_time(start_time)}"
  end
  defp do_render_duration(
    %{year: year, month: month, day: day} = start_time,
    %{year: year, month: month, day: day} = end_time) do
    "#{format_date(start_time)} at #{format_time(start_time)} - #{format_time(end_time)}"
  end
  defp do_render_duration(start_time, end_time) do
    "#{format_date(start_time)} #{format_time(start_time)} - #{format_date(end_time)} #{format_time(end_time)}"
  end

  defp format_time(time) do
    Timex.format!(time, "{h12}:{m}{am}")
  end
end
