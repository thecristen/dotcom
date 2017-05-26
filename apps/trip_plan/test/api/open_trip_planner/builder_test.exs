defmodule TripPlan.Api.OpenTripPlanner.BuilderTest do
  use ExUnit.Case, async: true
  import TripPlan.Api.OpenTripPlanner, only: [config: 1]
  import TripPlan.Api.OpenTripPlanner.Builder

  describe "build_params/1" do
    test "depart_at sets date/time options" do
      expected = {:ok, %{
                     "date" => "2017-05-22",
                     "time" => "12:04pm",
                     "arriveBy" => "false"
                  }}
      actual = build_params(depart_at: DateTime.from_naive!(~N[2017-05-22T16:04:20], "Etc/UTC"))
      assert expected == actual
    end

    test "arrive_by sets date/time options" do
      expected = {:ok, %{
                     "date" => "2017-05-22",
                     "time" => "12:04pm",
                     "arriveBy" => "true"
                  }}
      actual = build_params(arrive_by: DateTime.from_naive!(~N[2017-05-22T16:04:20], "Etc/UTC"))
      assert expected == actual
    end

    test "wheelchair_accessible? sets wheelchair option" do
      expected = {:ok, %{
                     "wheelchair" => "true"
                  }}
      actual = build_params(wheelchair_accessible?: true)
      assert expected == actual

      expected = {:ok, %{}}
      actual = build_params(wheelchair_accessible?: false)
      assert expected == actual
    end

    test "max_walk_distance sets maxWalkDistance in meters" do
      expected = {:ok, %{
                     "maxWalkDistance" => "1609.5"
                  }}
      actual = build_params(max_walk_distance: 1609.5)
      assert expected == actual
    end

    test "personal_mode of :drive adds the car mode" do
      car_mode = config(:car_mode)
      expected = {:ok, %{
                     "mode" => "#{car_mode},WALK,TRANSIT"
                  }}
      actual = build_params(personal_mode: :drive)
      assert actual == expected
    end

    test "personal_mode of :walk adds the walk mode" do
      expected = {:ok, %{
                     "mode" => "WALK,TRANSIT"
                  }}
      actual = build_params(personal_mode: :walk)
      assert actual == expected
    end

    test "bad options return an error" do
      expected = {:error, {:bad_param, {:bad, :arg}}}
      actual = build_params(bad: :arg)
      assert expected == actual
    end
  end
end
