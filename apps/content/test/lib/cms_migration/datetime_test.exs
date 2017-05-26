defmodule Content.CmsMigration.DatetimeTest do
  use ExUnit.Case, async: true
  alias Content.CmsMigration.DatetimeError
  import Content.CmsMigration.Datetime

  describe "parse_time!/1" do
    test "formats compound time formats to a consistent format" do
      assert parse_time!("2PM") == ~T[14:00:00]
      assert parse_time!("2:00PM") == ~T[14:00:00]
      assert parse_time!("0200PM") == ~T[14:00:00]
      assert parse_time!("1000AM") == ~T[10:00:00]
    end

    test "raises an error when unable to format the time" do
      error = "Unable to convert '200PM' to a datetime."
      assert_raise DatetimeError, error, fn ->
        assert parse_time!("200PM")
      end
    end
  end

  describe "parse_date!/1" do
    test "formats compound date formats to a consistent format" do
      assert parse_date!("April 15, 2017") == ~D[2017-04-15]
      assert parse_date!("April 15, 2017 ") == ~D[2017-04-15]
      assert parse_date!("April, 15 2017") == ~D[2017-04-15]
      assert parse_date!("April 15,2017") == ~D[2017-04-15]
      assert parse_date!("4/15/2017") == ~D[2017-04-15]
      assert parse_date!("04/15/2017") == ~D[2017-04-15]
    end

    test "raises an error when the date cannot be formatted" do
      error = "Unable to convert 'invalid' to a datetime."

      assert_raise DatetimeError, error, fn ->
        parse_date!("invalid")
      end
    end
  end

  describe "parse_utc_datetime/2" do
    test "returns the date and time as a datetime in UTC" do
      date = "March 20, 2017"
      time = "10:00AM"
      timezone = "America/New_York"

      expected_date_time = DateTime.from_naive!(~N[2017-03-20 14:00:00], "Etc/UTC")
      assert parse_utc_datetime(date, time, timezone) == expected_date_time
    end
  end
end
