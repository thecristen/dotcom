defmodule SiteWeb.ContentView do
  use SiteWeb, :view
  import SiteWeb.TimeHelpers

  alias Content.Field.File
  alias Content.Paragraph

  alias Content.Paragraph.{
    Accordion,
    Callout,
    ColumnMulti,
    CustomHTML,
    DescriptionList,
    DescriptiveLink,
    FareCard,
    FilesGrid,
    PeopleGrid,
    TitleCardSet,
    Unknown,
    UpcomingBoardMeetings
  }

  alias Phoenix.HTML.Tag
  alias Site.ContentRewriter

  defdelegate fa_icon_for_file_type(mime), to: Site.FontAwesomeHelpers

  @spec render_paragraph(Paragraph.t(), Plug.Conn.t()) :: Phoenix.HTML.safe()
  def render_paragraph(%CustomHTML{} = para, conn) do
    render("_custom_html.html", paragraph: para, conn: conn)
  end

  def render_paragraph(%DescriptiveLink{} = para, conn) do
    render("_descriptive_link.html", paragraph: para, conn: conn)
  end

  def render_paragraph(%TitleCardSet{} = para, conn) do
    render("_title_card_set.html", paragraph: para, conn: conn)
  end

  def render_paragraph(%UpcomingBoardMeetings{} = para, conn) do
    render("_upcoming_board_meetings.html", paragraph: para, conn: conn)
  end

  def render_paragraph(%PeopleGrid{} = para, conn) do
    render("_people_grid.html", paragraph: para, conn: conn)
  end

  def render_paragraph(%DescriptionList{} = description_list, conn) do
    render("_description_list.html", description_list: description_list, conn: conn)
  end

  def render_paragraph(%FareCard{} = fare_card, conn) do
    render("_fare_card.html", fare_card: fare_card, conn: conn)
  end

  def render_paragraph(%FilesGrid{} = para, _) do
    render("_files_grid.html", paragraph: para)
  end

  def render_paragraph(%ColumnMulti{} = para, conn) do
    if ColumnMulti.is_grouped?(para) do
      grouped_fare_card_data =
        para.columns
        |> nested_paragraphs()
        |> grouped_fare_card_data()

      render(
        "_grouped_fare_card.html",
        fare_cards: grouped_fare_card_data,
        conn: conn
      )
    else
      render("_column_multi.html", paragraph: para, conn: conn)
    end
  end

  def render_paragraph(%Accordion{} = para, conn) do
    render("_accordion.html", paragraph: para, conn: conn)
  end

  def render_paragraph(%Callout{} = entity, conn) do
    render("_callout.html", entity: entity, conn: conn)
  end

  def render_paragraph(%Unknown{} = para, _) do
    render("_unknown.html", paragraph: para)
  end

  def file_description(%File{description: desc}) when not is_nil(desc) and desc != "" do
    desc
  end

  def file_description(%File{url: url}) do
    url |> Path.basename() |> URI.decode()
  end

  @doc "Nicely renders the duration of an event, given two DateTimes."
  @spec render_duration(NaiveDateTime.t() | DateTime.t(), NaiveDateTime.t() | DateTime.t() | nil) ::
          String.t()
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

  @doc "Sets CMS content wrapper classes based on presence of sidebar elements {left, right}"
  @spec sidebar_classes({boolean, boolean}) :: String.t()
  def sidebar_classes({true, _}), do: "c-cms--with-sidebar c-cms--sidebar-left"
  def sidebar_classes({false, true}), do: "c-cms--with-sidebar c-cms--sidebar-right"
  def sidebar_classes({false, false}), do: "c-cms--no-sidebar"

  @spec grid(ColumnMulti.t()) :: integer
  def grid(%ColumnMulti{columns: columns}) do
    div(12, max(Enum.count(columns), 2))
  end

  @spec extend_width(Keyword.t()) :: Phoenix.HTML.safe()
  def extend_width(do: content) do
    Tag.content_tag :div, class: "c-media c-media--type-table" do
      inner_wrappers(do: content)
    end
  end

  @spec extend_width_if(boolean, Keyword.t()) :: Phoenix.HTML.safe()
  def extend_width_if(true, do: content), do: extend_width(do: content)

  def extend_width_if(false, do: content), do: content

  @spec full_bleed(Keyword.t(), Keyword.t()) :: Phoenix.HTML.safe()
  def full_bleed(classes \\ Keyword.new(), do: content) do
    Tag.content_tag :div,
      class: "c-media c-media--type-callout #{Keyword.get(classes, :wrapper_class, "")}" do
      inner_wrappers do
        Tag.content_tag(
          :div,
          [class: "u-full-bleed #{Keyword.get(classes, :callout_class, "")}"],
          do: content
        )
      end
    end
  end

  @spec full_bleed_if(boolean, Keyword.t(), Keyword.t()) :: Phoenix.HTML.safe()
  def full_bleed_if(condition, classes \\ Keyword.new(), content)

  def full_bleed_if(true, classes, do: content), do: full_bleed(classes, do: content)

  def full_bleed_if(false, _, do: content), do: content

  defp inner_wrappers(do: content) do
    Tag.content_tag :div, class: "c-media__content" do
      Tag.content_tag(:div, [class: "c-media__element"], do: content)
    end
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
         %{year: year, month: month, day: day} = end_time
       ) do
    "#{format_date(start_time)} at #{format_time(start_time)} - #{format_time(end_time)}"
  end

  defp do_render_duration(start_time, end_time) do
    "#{format_date(start_time)} #{format_time(start_time)} - #{format_date(end_time)} #{
      format_time(end_time)
    }"
  end

  defp format_time(time) do
    Timex.format!(time, "{h12}:{m}{am}")
  end

  defp nested_paragraphs(columns), do: columns |> Enum.flat_map(& &1.paragraphs)

  defp grouped_fare_card_data(paragraphs) when is_list(paragraphs) do
    Enum.map(
      paragraphs,
      &%FareCard{fare_token: &1.fare_token, note: &1.note}
    )
  end

  defp grouped_fare_card_data(_) do
    nil
  end
end
