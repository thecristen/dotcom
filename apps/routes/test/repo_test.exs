defmodule Routes.RepoTest do
  use ExUnit.Case, async: true

  describe "all/0" do
    test "returns something" do
      assert Routes.Repo.all != []
    end

    test "parses the data into Route structs" do
      assert Routes.Repo.all |> List.first == %Routes.Route{
        id: "Blue",
        type: 1,
        name: "Blue Line",
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

  test "by_type/1 only returns routes of a given type" do
    one = Routes.Repo.by_type(1)
    assert one |> Enum.all?(fn route -> route.type == 1 end)
    assert one != []
  end

  test "get/1 returns a single route" do
    assert %Routes.Route{
      id: "Red",
      name: "Red Line",
      type: 1
    } = Routes.Repo.get("Red")

    assert nil == Routes.Repo.get("_unknown_route")
  end

  test "key bus routes are tagged" do
    assert %Routes.Route{
      key_route?: true}
    = Routes.Repo.get("1")

    assert %Routes.Route{
      key_route?: true}
    = Routes.Repo.get("741")

    assert %Routes.Route{
      key_route?: false}
    = Routes.Repo.get("47")
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

    test "returns multiple headsigns for a direction" do
      headsigns = Routes.Repo.headsigns("66")

      assert headsigns == %{
        0 => ["Harvard via Allston", "Brighton Center via Brookline", "Union Square, Allston via Brookline"],
        1 => ["Dudley via Allston"]
      }
    end

    test "returns headsigns for rail routes" do
      headsigns = Routes.Repo.headsigns("CR-Lowell")

      assert headsigns == %{
        0 => ["Lowell", "Anderson/ Woburn", "Haverhill"],
        1 => ["North Station"]
      }
    end

    test "returns headsigns for subway routes" do
      headsigns = Routes.Repo.headsigns("Red")

      assert headsigns == %{
        0 => ["Ashmont", "Braintree"],
        1 => ["Alewife"]
      }
    end

    test "returns headsigns for boats" do
      headsigns = Routes.Repo.headsigns("Boat-F1")

      assert headsigns == %{
        0 => [],
        1 => []
      }
    end
  end
end
