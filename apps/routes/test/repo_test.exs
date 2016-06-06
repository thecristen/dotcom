defmodule Routes.RepoTest do
  use ExUnit.Case

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
end
