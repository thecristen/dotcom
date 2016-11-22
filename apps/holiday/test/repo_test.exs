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
end
