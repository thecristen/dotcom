defmodule TripPlan.Api.OpenTripPlanner.ParserTest do
  use ExUnit.Case, async: true
  import TripPlan.Api.OpenTripPlanner.Parser
  alias TripPlan.{Itinerary, NamedPosition, PersonalDetail, PersonalDetail.Step, TransitDetail}

  @fixture File.read!("test/fixture/north_station_to_park_plaza.json")
  @parsed parse_json!(@fixture)

  describe "parse_json/1" do
    test "returns an error with invalid JSON" do
      assert {:error, _} = parse_json("")
    end

    test "returns a list of Itinerary structs" do
      for i <- @parsed do
        assert %Itinerary{} = i
      end
      assert [first, _, _] = @parsed
      assert first.start == Timex.to_datetime(~N[2017-05-19T13:48:58], "America/New_York")
      assert first.stop == Timex.to_datetime(~N[2017-05-19T14:05:19], "America/New_York")
    end

    test "an itinerary has legs" do
      first = List.first(@parsed)
      [walk_leg, subway_leg, other_walk_leg] = first.legs
      assert %NamedPosition{name: "stop North Station "} = walk_leg.from
      assert %NamedPosition{stop_id: "70026"} = walk_leg.to
      assert is_binary(walk_leg.polyline)
      assert %DateTime{} = walk_leg.start
      assert %DateTime{} = walk_leg.stop
      assert %PersonalDetail{} = walk_leg.mode

      assert %TransitDetail{} = subway_leg.mode
      assert %PersonalDetail{} = other_walk_leg.mode
    end

    test "walk legs have distance and step plans" do
      [walk_leg, _, other_walk_leg] = List.first(@parsed).legs
      assert walk_leg.mode.distance == 0.897
      assert walk_leg.mode.steps == [
        %Step{
          distance: 0.897,
          relative_direction: :depart,
          absolute_direction: :southwest,
          street_name: "Causeway Street"
        }
      ]
      assert other_walk_leg.mode.steps == [
        %Step{
          distance: 138.02,
          relative_direction: :depart,
          absolute_direction: :south,
          street_name: "Washington Street"
        },
        %Step{
          distance: 111.909,
          relative_direction: :right,
          absolute_direction: :west,
          street_name: "Oak Street West"
        },
        %Step{
          distance: 79.385,
          relative_direction: :continue,
          absolute_direction: :west,
          street_name: "Tremont Street"
        }
      ]
    end

    test "subway plans have trip information" do
      [_, subway_leg, _] = List.first(@parsed).legs
      assert subway_leg.mode.route_id == "Orange"
      assert subway_leg.mode.trip_id == "33932853"
    end
  end
end
