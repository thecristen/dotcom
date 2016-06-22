defmodule Routes.RepoTest do
  use ExUnit.Case, async: true

  test ".all returns something" do
    assert Routes.Repo.all != []
  end

  test ".all parses the data into Route structs" do
    assert Routes.Repo.all |> List.first == %Routes.Route{
      id: "Blue",
      type: 1,
      name: "Blue Line"
    }
  end

  test ".all parses a long name for the Green Line" do
    [route] = Routes.Repo.all
    |> Enum.filter(&(&1.id == "Green-B"))
    assert route == %Routes.Route{
      id: "Green-B",
      type: 0,
      name: "Green Line B"
    }
  end

  test ".all parses a short name instead of a long one" do
    [route] = Routes.Repo.all
    |> Enum.filter(&(&1.name == "SL1"))
    assert route == %Routes.Route{
      id: "741",
      type: 3,
      name: "SL1"
    }
  end

  test ".all parses a short_name if there's no long name" do
    [route] = Routes.Repo.all
    |> Enum.filter(&(&1.name == "23"))
    assert route == %Routes.Route{
      id: "23",
      type: 3,
      name: "23"
    }
  end

  test ".all filters out 'hidden' routes'" do
    all = Routes.Repo.all
    assert all |> Enum.filter(fn route -> route.name == "24/27" end) == []
  end

  test ".by_type only returns routes of a given type" do
    one = Routes.Repo.by_type(1)
    assert one |> Enum.all?(fn route -> route.type == 1 end)
    assert one != []
  end
end
