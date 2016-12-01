defmodule Holiday.RepoTest do
  use ExUnit.Case

  describe "all/0" do
    test "returns a list of Holidays" do
      actual = Holiday.Repo.all

      assert actual != []
      assert Enum.all?(actual, &match?(%Holiday{}, &1))
    end
  end

  describe "by_date/1" do
    test "returns Christmas Day on 2016-12-25" do
      date = ~D[2018-12-25]
      assert Holiday.Repo.by_date(date) ==
        [%Holiday{date: date, name: "Christmas Day"}]
    end

    test "returns Veterans Day (Observed) on 2018-11-12" do
      date = ~D[2018-11-12]
      assert Holiday.Repo.by_date(date) ==
        [%Holiday{date: date, name: "Veterans’ Day (Observed)"}]
    end

    test "returns nothing for 2018-11-01" do
      date = ~D[2016-11-01]
      assert Holiday.Repo.by_date(date) == []
    end
  end
  describe "upcoming_holidays/1" do
    test "Returns November Holidays" do
      date = ~D[2016-11-01]
      assert %Holiday{date: ~D[2016-11-11], name: "Veterans’ Day"} in Holiday.Repo.upcoming_holidays(date)
      assert %Holiday{date: ~D[2016-11-24], name: "Thanksgiving Day"} in Holiday.Repo.upcoming_holidays(date)
    end
    test "Includes holiday on current day" do
      date = ~D[2016-11-11]
      assert %Holiday{date: ~D[2016-11-11], name: "Veterans’ Day"} in Holiday.Repo.upcoming_holidays(date)
    end
    test "Past holidays are not included" do
      date = ~D[2016-11-12]
      for holiday <- Holiday.Repo.upcoming_holidays(date) do
        assert Timex.after?(holiday.date, date)
      end
    end
  end
end

defmodule Holiday.Repo.HelpersTest do
  use ExUnit.Case
  doctest Holiday.Repo.Helpers
end
