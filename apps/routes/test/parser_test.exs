defmodule Routes.ParserTest do
  use ExUnit.Case, async: true

  import Routes.Parser
  alias Routes.Shape
  alias JsonApi.Item

  describe "parse_shape/1" do
    test "ignores shapes with a negative priority" do
      item = %Item{attributes: %{"priority" => -1}}
      assert parse_shape(item) == []
    end

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
