defmodule Site.EventQueryBuilderTest do
  use ExUnit.Case
  alias Site.EventQueryBuilder

  describe "upcoming_events/1" do
    test "returns query params to find upcoming events" do
      start_date = ~D[2017-04-10]

      assert EventQueryBuilder.upcoming_events(start_date) == %{
        start_time_gt: "2017-04-10",
        start_time_lt: "2017-05-10"
      }
    end
  end
end
