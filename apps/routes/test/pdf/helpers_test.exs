defmodule Routes.Pdf.HelpersTest do
  use ExUnit.Case, async: true
  import Routes.Pdf.Helpers

  describe "parse_date/2" do
    test "turns a row into a {date, url} tuple" do
      row = ["route", "url", "2017-03-15"]
      expected = {~D[2017-03-15], "url"}
      actual = parse_date(row)
      assert actual == expected
    end
  end
end
