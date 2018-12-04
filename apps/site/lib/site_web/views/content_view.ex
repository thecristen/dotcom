defmodule SiteWeb.ContentView do
  use SiteWeb, :view
  import SiteWeb.TimeHelpers

  alias Content.Field.File
  alias Content.Paragraph
  alias Content.Paragraph.{ColumnMulti, CustomHTML, FareCard, FilesGrid,
    PeopleGrid, Tabs, TitleCardSet, Unknown, UpcomingBoardMeetings}
  alias Phoenix.HTML.Tag
  alias Site.ContentRewriter

  defdelegate fa_icon_for_file_type(mime), to: Site.FontAwesomeHelpers

  @spec render_paragraph(Paragraph.t, Plug.Conn.t) :: Phoenix.HTML.safe
  def render_paragraph(%CustomHTML{} = para, conn) do
    ContentRewriter.rewrite(para.body, conn)
  end
  def render_paragraph(%TitleCardSet{} = para, conn) do
    render "_title_card_set.html", paragraph: para, conn: conn
  end
  def render_paragraph(%UpcomingBoardMeetings{} = para, conn) do
    render "_upcoming_board_meetings.html", paragraph: para, conn: conn
  end
  def render_paragraph(%PeopleGrid{} = para, conn) do
    render "_people_grid.html", paragraph: para, conn: conn
  end
  def render_paragraph(%FareCard{} = fare_card, conn) do
    render "_fare_card.html", fare_card: fare_card, conn: conn
  end
  def render_paragraph(%FilesGrid{} = para, _) do
    render "_files_grid.html", paragraph: para
  end
  def render_paragraph(%ColumnMulti{} = para, conn) do
    render "_column_multi.html", paragraph: para, conn: conn
  end
  def render_paragraph(%Tabs{} = para, conn) do
    render "_tabs.html", paragraph: para, conn: conn
  end
  def render_paragraph(%Unknown{} = para, _) do
    render "_unknown.html", paragraph: para
  end

  def file_description(%File{description: desc}) when not is_nil(desc) and desc != "" do
    desc
  end
  def file_description(%File{url: url}) do
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

  def grid(%ColumnMulti{columns: columns}) do
    div(12,  max(Enum.count(columns), 2))
  end

  @spec extend_width_if(boolean, Keyword.t) :: Phoenix.HTML.safe
  def extend_width_if(true, [do: content]) do
    Tag.content_tag(:div, class: "c-media c-media--type-table") do
      Tag.content_tag(:div, class: "c-media__content") do
        Tag.content_tag :div, [class: "c-media__element"], [do: content]
      end
    end
  end
  def extend_width_if(false, [do: content]) do
    content
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
