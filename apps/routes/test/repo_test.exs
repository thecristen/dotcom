defmodule Routes.RepoTest do
  use ExUnit.Case, async: true

  describe "all/0" do
    test "returns something" do
      assert Routes.Repo.all != []
    end

    test "parses the data into Route structs" do
      assert Routes.Repo.all |> List.first == %Routes.Route{
        id: "Red",
        type: 1,
        name: "Red Line",
        direction_names: %{0 => "Southbound", 1 => "Northbound"},
        key_route?: true
      }
    end

    test "parses a long name for the Green Line" do
      [route] = Routes.Repo.all
      |> Enum.filter(&(&1.id == "Green-B"))
      assert route == %Routes.Route{
        id: "Green-B",
        type: 0,
        name: "Green Line B",
        direction_names: %{0 => "Westbound", 1 => "Eastbound"},
        key_route?: true
      }
    end

    test "parses a short name instead of a long one" do
      [route] = Routes.Repo.all
      |> Enum.filter(&(&1.name == "SL1"))
      assert route == %Routes.Route{
        id: "741",
        type: 3,
        name: "SL1",
        key_route?: true
      }
    end

    test "parses a short_name if there's no long name" do
      [route] = Routes.Repo.all
      |> Enum.filter(&(&1.name == "23"))
      assert route == %Routes.Route{
        id: "23",
        type: 3,
        name: "23",
        key_route?: true
      }
    end

    test "filters out 'hidden' routes'" do
      all = Routes.Repo.all
      assert all |> Enum.filter(fn route -> route.name == "24/27" end) == []
    end

  end

  describe "by_type/1" do
    test "only returns routes of a given type" do
      one = Routes.Repo.by_type(1)
      assert one |> Enum.all?(fn route -> route.type == 1 end)
      assert one != []
      assert one == Routes.Repo.by_type([1])
    end

    test "filtering by a list keeps the routes in their global order" do
      assert Routes.Repo.by_type([0, 1, 2, 3, 4]) == Routes.Repo.all
    end
  end

  describe "get/1" do
    test "returns a single route" do
      assert %Routes.Route{
        id: "Red",
        name: "Red Line",
        type: 1
      } = Routes.Repo.get("Red")
    end

    test "returns nil for an unknown route" do
      refute Routes.Repo.get("_unknown_route")
    end

    test "returns a hidden route" do
      assert %Routes.Route{id: "746"} = Routes.Repo.get("746")
    end
  end

  test "key bus routes are tagged" do
    assert %Routes.Route{key_route?: true} = Routes.Repo.get("1")
    assert %Routes.Route{key_route?: true} = Routes.Repo.get("741")
    assert %Routes.Route{key_route?: false} = Routes.Repo.get("47")
  end

  describe "headsigns/1" do
    test "returns empty lists when route has no trips" do
      headsigns = Routes.Repo.headsigns("tripless")

      assert headsigns == %{
        0 => [],
        1 => []
      }
    end

    test "returns keys for both directions" do
      headsigns = Routes.Repo.headsigns("1")

      assert Map.keys(headsigns) == [0, 1]
    end

    test "returns basic headsign data" do
      headsigns = Routes.Repo.headsigns("1")

      assert headsigns == %{
        0 => ["Harvard"],
        1 => ["Dudley"]
      }
    end

    test "returns headsigns for primary route for rail routes" do
      headsigns = Routes.Repo.headsigns("CR-Lowell")
      assert "Lowell" in headsigns[0]
      refute "Haverhill" in headsigns[0]
      assert "North Station" in headsigns[1]
    end

    test "returns headsigns for subway routes" do
      headsigns = Routes.Repo.headsigns("Red")

      assert "Ashmont" in headsigns[0]
      assert "Braintree" in headsigns[0]
      assert "Alewife" in headsigns[1]
    end
  end

  describe "calculate_headsigns" do
    test "returns an empty list for an error" do
      error = %JsonApi.Error{}
      assert Routes.Repo.calculate_headsigns(error) == []
    end

    test "returns headsigns sorted by frequency" do
      data = %JsonApi{
        data: [
          %JsonApi.Item{attributes: %{"headsign" => ""},
                        relationships: %{"route" => [%{id: "primary"}]}
          },
          %JsonApi.Item{attributes: %{"headsign" => "first"},
                        relationships: %{"route" => [%{id: "primary"}]}
          },
          %JsonApi.Item{attributes: %{"headsign" => "second"},
                        relationships: %{"route" => [%{id: "primary"}]}
          },
          %JsonApi.Item{attributes: %{"headsign" => "first"},
                        relationships: %{"route" => [%{id: "primary"}]}
          },
        ]
      }
      assert Routes.Repo.calculate_headsigns(data, "primary") == ["first", "second"]
    end

    test "filters out items with route ids not matching primary route" do
      data = %JsonApi{
        data: [
          %JsonApi.Item{attributes: %{"headsign" => ""},
                        relationships: %{"route" => [%{id: "primary"}]}
          },
          %JsonApi.Item{attributes: %{"headsign" => "first"},
                        relationships: %{"route" => [%{id: "primary"}]}
          },
          %JsonApi.Item{attributes: %{"headsign" => "second"},
                        relationships: %{"route" => [%{id: "other"}]}
          },
          %JsonApi.Item{attributes: %{"headsign" => "first"},
                        relationships: %{"route" => [%{id: "primary"}]}
          },
        ]
      }
      assert Routes.Repo.calculate_headsigns(data, "primary") == ["first"]
    end
  end

  describe "by_stop/1" do
    test "returns stops from different lines" do
      assert [
        %Routes.Route{id: "Blue", type: 1},
        %Routes.Route{id: "119", type: 3},
      ] = Routes.Repo.by_stop("place-bmmnl") #Beachmont
    end

    test "can specify type as param" do
      assert [
        %Routes.Route{id: "119", type: 3},
      ] = Routes.Repo.by_stop("place-bmmnl", type: 3) #Beachmont
    end

    test "returns empty list if no routes of that type serve that stop" do
      assert [] = Routes.Repo.by_stop("place-bmmnl", type: 0)
    end

    test "returns no routes on nonexistant station" do
      assert [] = Routes.Repo.by_stop("thisstopdoesntexist")
    end
  end

  describe "route_hidden?/1" do
    test "Returns true for hidden routes" do
      hidden_routes = ["746", "2427", "3233", "3738", "4050", "627", "725", "8993", "116117", "214216",
                       "441442", "9701", "9702", "9703", "Logan-Airport", "CapeFlyer"]
      for route_id <- hidden_routes do
        assert Routes.Repo.route_hidden?(%{id: route_id})
      end
    end

    test "Returns false for non hidden routes" do
      visible_routes = ["SL1", "66", "1", "742"]
      for route_id <- visible_routes do
        refute Routes.Repo.route_hidden?(%{id: route_id})
      end
    end
  end

  describe "handle_response/1" do
    test "parses routes" do
      response = %JsonApi{data: [
        %JsonApi.Item{attributes: %{"description" => "Local Bus", "direction_names" => ["Outbound", "Inbound"],
          "long_name" => "", "short_name" => "16", "sort_order" => 1600, "type" => 3},
          id: "16", relationships: %{}, type: "route"},
        %JsonApi.Item{attributes: %{"description" => "Local Bus", "direction_names" => ["Outbound", "Inbound"],
          "long_name" => "", "short_name" => "36", "sort_order" => 3600, "type" => 3},
          id: "36", relationships: %{}, type: "route"},
      ], links: %{}}
      assert {:ok, [%Routes.Route{id: "16"}, %Routes.Route{id: "36"}]} = Routes.Repo.handle_response(response)
    end

    test "removes hidden routes" do
      response = %JsonApi{data: [
        %JsonApi.Item{attributes: %{"description" => "Local Bus", "direction_names" => ["Outbound", "Inbound"],
          "long_name" => "", "short_name" => "36", "sort_order" => 3600, "type" => 3},
          id: "36", relationships: %{}, type: "route"},
        %JsonApi.Item{attributes: %{"description" => "Limited Service", "direction_names" => ["Outbound", "Inbound"],
          "long_name" => "", "short_name" => "9701", "sort_order" => 970_100, "type" => 3},
          id: "9701", relationships: %{}, type: "route"},
      ], links: %{}}
      assert {:ok, [%Routes.Route{id: "36"}]} = Routes.Repo.handle_response(response)
    end

    test "passes errors through" do
      error = {:error, %HTTPoison.Error{id: nil, reason: :timeout}}
      assert Routes.Repo.handle_response(error) == error
    end
  end

  describe "get_shapes/2" do
    test "Get valid response for bus route" do
      shapes = Routes.Repo.get_shapes("9", 1)
      shape = List.first(shapes)

      assert Enum.count(shapes) >= 2
      assert is_binary(shape.id)
      assert Enum.count(shape.stop_ids) >= 27
    end

    test "get different number of shapes from same route depending on filtering" do
      all_shapes = Routes.Repo.get_shapes("Green-E", 0, false)
      priority_shapes = Routes.Repo.get_shapes("Green-E", 0)

      refute Enum.count(all_shapes) == Enum.count(priority_shapes)
    end
  end

  describe "get_shape/1" do
    shape = "903_0018"
    |> Routes.Repo.get_shape()
    |> List.first()

    assert shape.id == "903_0018"
  end
end
