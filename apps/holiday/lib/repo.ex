defmodule Holiday.Repo.Helpers do
  def make_holiday({name, list_of_dates}, start_year) do
    list_of_dates
    |> Enum.with_index(start_year)
    |> Enum.map(fn {{month, day}, year} ->
      %Holiday{
        date: Timex.to_date({year, month, day}),
        name: name}
    end)
  end

  @doc "If a holiday falls on a Sunday, it is observed on that Monday"
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
end
