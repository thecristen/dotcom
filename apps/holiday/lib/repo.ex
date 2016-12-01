defmodule Holiday.Repo.Helpers do
  @moduledoc """

  Helper functions used by the compilation of Holiday.Repo.

  """

  @doc """

  Generates a list of Holidays from the shorthand.

  iex> Holiday.Repo.Helpers.make_holiday({"Name", [{1, 2}, {3, 4}]}, 1000)
  [%Holiday{date: ~D[1000-01-02], name: "Name"},
   %Holiday{date: ~D[1001-03-04], name: "Name"}]
  """
  @spec make_holiday({String.t, [{1..2, 1..31}]}, non_neg_integer) :: [Holiday.t]
  def make_holiday({name, list_of_dates}, start_year) do
    list_of_dates
    |> Enum.with_index(start_year)
    |> Enum.map(fn {{month, day}, year} ->
      %Holiday{
        date: Timex.to_date({year, month, day}),
        name: name}
    end)
  end

  @doc """

  If a holiday falls on a Sunday, it is observed on that Monday.

  iex> Holiday.Repo.Helpers.observe_holiday(%Holiday{date: ~D[2018-11-11], name: "Name"})
  [%Holiday{date: ~D[2018-11-11], name: "Name"},
   %Holiday{date: ~D[2018-11-12], name: "Name (Observed)"}]

  iex> Holiday.Repo.Helpers.observe_holiday(%Holiday{date: ~D[2018-01-01], name: "Name"})
  [%Holiday{date: ~D[2018-01-01], name: "Name"}]
  """
  @spec observe_holiday(Holiday.t) :: [Holiday.t]
  def observe_holiday(%Holiday{date: date} = holiday) do
    if Timex.weekday(date) == 7 do # Sunday
      [holiday,
       %{holiday |
         date: date |> Timex.shift(days: 1),
         name: "#{holiday.name} (Observed)"}]
    else
      [holiday]
    end
  end

  @doc """

  Used by Map.new to build the Holiday map: returns the date as the key for the Map.

  iex> Holiday.Repo.Helpers.build_map(%Holiday{date: ~D[2016-01-01], name: "Name"})
  {~D[2016-01-01], %Holiday{date: ~D[2016-01-01], name: "Name"}}
  """
  def build_map(%Holiday{date: date} = holiday) do
    {date, holiday}
  end
end

defmodule Holiday.Repo do
  import Holiday.Repo.Helpers
  # from http://www.mass.gov/anf/employment-equal-access-disability/hr-policies/legal-holiday-calendar.html
  @start_year 2016
  @holidays [
    # { name, [{month, day}, {month, day}, ...]},
    {"New Years Day", [{1, 1}, {1, 1}, {1, 1}]},
    {"Martin Luther King Day", [{1, 18}, {1, 16}, {1, 15}]},
    {"President’s Day", [{2, 15}, {2, 20}, {2, 19}]},
    {"Patriots’ Day", [{4, 18}, {4, 17}, {4, 16}]},
    {"Memorial Day", [{5, 30}, {5, 29}, {5, 28}]},
    {"Independence Day", [{7, 4}, {7, 4}, {7, 4}]},
    {"Labor Day", [{9, 5}, {9, 4}, {9, 3}]},
    {"Columbus Day", [{10, 10}, {10, 9}, {10, 8}]},
    {"Veterans’ Day", [{11, 11}, {11, 11}, {11, 11}]},
    {"Thanksgiving Day", [{11, 24}, {11, 23}, {11, 22}]},
    {"Christmas Day", [{12, 25}, {12, 25}, {12, 25}]}]
  |> Enum.flat_map(&make_holiday(&1, @start_year))
  |> Enum.flat_map(&observe_holiday/1)
  |> Map.new(&build_map/1)

  @doc "Returns the list of Holidays"
  @spec all :: [Holiday.t]
  def all do
    Map.values(@holidays)
  end

  @doc "Returns the list of holidays for the given Date"
  @spec by_date(Date.t) :: [Holiday.t]
  def by_date(date) do
    case Map.fetch(@holidays, date) do
      {:ok, holiday} -> [holiday]
      _ -> []
    end
  end

  @doc "Returns the list of holidays in the given month that occur after or on given date"
  @spec upcoming_holidays(Date.t) :: [Holiday.t]
  def upcoming_holidays(date) do
    same_time_frame? = fn(tf, d) -> Map.fetch!(d, tf) == Map.fetch!(date, tf) end
    upcoming? = fn(%Holiday{date: h}) ->
      same_time_frame?.(:year, h) and same_time_frame?.(:month, h) and (same_time_frame?.(:day, h) or Timex.after?(h, date))
    end

    @holidays
    |> Map.values
    |> Enum.filter(upcoming?)
  end
end
