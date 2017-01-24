defmodule BuildCalendar do
  @type url :: String.t

  defmodule Calendar do
    @moduledoc """

    Represents a calendar for display.

    * previous_month_url: either a URL to get to the previous month, or nil if we shouldn't link to it
    * next_month_url: a URL to get to the next month
    * days: a list of BuildCalendar.Day structs, representing each day we're displaying for the calendar
    """
    @type t :: %__MODULE__{
      previous_month_url: String.t | nil,
      next_month_url: String.t,
      days: [BuildCalendar.Day.t],
      holidays: [Holiday.t]
    }
    defstruct [
      previous_month_url: nil,
      next_month_url: "",
      days: [],
      holidays: []
    ]

    @doc "Breaks the days of a Calendar into 1-week chunks."
    def weeks(%Calendar{days: days}) do
      Enum.chunk(days, 7)
    end
  end

  defmodule Day do
    @moduledoc """

    Represents a single day displayed for a Calendar.

    * date: the full date
    * month_relation: how this date relates to the month of the Calendar
    * selected?: true if the Day represents the currently selected date
    * holiday?: true if the Day is a holiday
    * url: a URL to set this Day as the selected one
    """
    @type month_relation :: :current | :previous | :next
    @type t :: %__MODULE__{
      date: Date.t,
      month_relation: month_relation,
      selected?: boolean,
      holiday?: boolean,
      url: BuildCalendar.url
    }

    defstruct [
      date: ~D[0000-01-01],
      month_relation: :current,
      selected?: false,
      holiday?: false,
      url: nil
    ]

    import Phoenix.HTML.Tag
    import Phoenix.HTML.Link

    @spec td(t) :: Phoenix.HTML.Safe.t
    def td(%Day{month_relation: :previous} = day) do
      content_tag :td, "", class: class(day)
    end
    def td(%Day{date: date, url: url} = day) do
      content_tag :td, class: class(day) do
        link "#{date.day}", to: url
      end
    end

    def class(day) do
      # The list is a tuple of {boolean, class_name}.  We filter out the
      # false booleans, then get the class names and join them.
      case [
        {Timex.weekday(day.date) > 5, "schedule-weekend"},
        {day.holiday?, "schedule-holiday"},
        {day.selected?, "schedule-selected"},
        {day.month_relation == :next, "schedule-next-month"},
      ]
      |> Enum.filter_map(&match?({true, _}, &1), &elem(&1, 1)) do
        [] -> nil
        classes -> Enum.join(classes, " ")
      end
    end
  end

  @typedoc "A function which, given some keyword arguments, returns a URL.  Used for building URLs to select dates."
  @type url_fn :: ((Keyword.t) -> url)

  @doc "Builds the links that will be displayed on the calenydar"
  @spec build(Date.t, [Holiday.t], url_fn) :: BuildCalendar.Calendar.t
  def build(selected, holidays, url_fn) do
    holiday_set = MapSet.new(holidays, & &1.date)
    %BuildCalendar.Calendar{
      previous_month_url: previous_month_url(selected, Util.service_date(), url_fn),
      next_month_url: next_month_url(selected, url_fn),
      days: build_days(selected, holiday_set, url_fn),
      holidays: holidays
    }
  end

  @spec previous_month_url(Date.t, Date.t, url_fn) :: String.t | nil
  defp previous_month_url(%Date{year: year, month: month}, %Date{year: year, month: month}, _) do
    nil
  end
  defp previous_month_url(date, _selected, url_fn) do
    url_fn.(date: date |> Timex.beginning_of_month |> Timex.shift(months: -1) |> format_date)
  end

  @spec next_month_url(Date.t, url_fn) :: String.t
  defp next_month_url(date, url_fn) do
    url_fn.(date: date |> Timex.beginning_of_month |> Timex.shift(months: 1) |> format_date)
  end

  @spec build_days(Date.t, MapSet.t, url_fn) :: [BuildCalendar.Day.t]
  defp build_days(selected, holiday_set, url_fn) do
    last_day_of_previous_month = selected
    |> Timex.beginning_of_month
    |> Timex.shift(days: -1)

    last_day_of_this_month = Timex.end_of_month(selected)

    for date <- day_enum(first_day(selected), last_day(selected)) do
      %BuildCalendar.Day{
        date: date,
        url: url_fn.(date: format_date(date), date_select: nil),
        month_relation: month_relation(date, last_day_of_previous_month, last_day_of_this_month),
        selected?: date == selected,
        holiday?: MapSet.member?(holiday_set, date)
      }
    end
  end

  @spec first_day(Date.t) :: Date.t
  defp first_day(date) do
    date
    |> Timex.beginning_of_month
    |> Timex.beginning_of_week(7) # Sunday
  end

  @spec last_day(Date.t) :: Date.t
  defp last_day(date) do
    # at the last day of the month, add a week, then go the end of the
    # current week.  We use Monday as the start of the week so we end on a
    # Sunday.
    date
    |> Timex.end_of_month
    |> Timex.shift(days: 7)
    |> Timex.end_of_week(1)
  end

  # Given a first day and a last day, returns a list of Date.t, inclusive of
  # both first and exclusive of last.
  @spec day_enum(Date.t, Date.t) :: [Date.t]
  defp day_enum(first, last) do
    do_day_enum(first, last, [])
  end

  @spec do_day_enum(Date.t, Date.t, [Date.t]) :: [Date.t]
  defp do_day_enum(first, first, acc) do
    Enum.reverse(acc)
  end
  defp do_day_enum(first, last, acc) do
    acc = [first | acc]
    next = Timex.shift(first, days: 1)
    do_day_enum(next, last, acc)
  end

  @spec format_date(Date.t) :: String.t
  defp format_date(%Date{} = date) do
    Timex.format!(date, "{ISOdate}")
  end

  @spec month_relation(Date.t, Date.t, Date.t) :: __MODULE__.Day.month_relation
  defp month_relation(date, last_day_of_previous_month, last_day_of_this_month) do
    cond do
      Timex.after?(date, last_day_of_this_month) ->
        :next
      Timex.after?(date, last_day_of_previous_month) ->
        :current
      true ->
        :previous
    end
  end
end
