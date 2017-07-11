defmodule Routes.ParserTest do
  use ExUnit.Case, async: true

  import Routes.Parser
  alias Routes.Shape
  alias JsonApi.Item

  describe "parse_route/1" do
    test "does not pick an empty name for bus routes" do
      item = %Item{
        id: "746",
        attributes: %{
          "type" => 3,
          "short_name" => "",
          "long_name" => "Silver Line Waterfront",
          "direction_names" => ["zero", "one"]
        }
      }
      parsed = parse_route(item)
      assert parsed.name == "Silver Line Waterfront"
    end

    test "prefers the short name for bus routes" do
      item = %Item{
        id: "id",
        attributes: %{
          "type" => 3,
          "short_name" => "short",
          "long_name" => "long",
          "direction_names" => ["zero", "one"]
        }
      }
      parsed = parse_route(item)
      assert parsed.name == "short"
    end

    test "prefers the long name for other routes" do
      item = %Item{
        id: "id",
        attributes: %{
          "type" => 2,
          "short_name" => "short",
          "long_name" => "long",
          "direction_names" => ["zero", "one"]
        }
      }
      parsed = parse_route(item)
      assert parsed.name == "long"
    end

    test "does not pick an empty name for other routes" do
      item = %Item{
        id: "id",
        attributes: %{
          "type" => 2,
          "short_name" => "short",
          "long_name" => "",
          "direction_names" => ["zero", "one"]
        }
      }
      parsed = parse_route(item)
      assert parsed.name == "short"
    end
  end

  describe "parse_shape/1" do
    test "parses a shape" do
      item = %Item{id: "shape_id",
                    attributes: %{
                      "name" => "name",
                      "direction_id" => 1,
                      "polyline" => "polyline"},
                    relationships: %{
                      "stops" => [
                        %Item{id: "1"},
                        %Item{id: "2"}]}}
      assert parse_shape(item) == [%Shape{
                                      id: "shape_id",
                                      name: "name",
                                      stop_ids: ["1", "2"],
                                      direction_id: 1,
                                      polyline: "polyline"}]
    end
  end
end
