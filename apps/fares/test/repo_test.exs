defmodule Fares.RepoTest do
  use ExUnit.Case, async: true
  alias Fares.Repo

  test "it finds the one way fare given a zone" do
    assert Repo.one_way("6") == "10.00"
  end

  test "it finds the one way reduced fare given a zone" do
    assert Repo.one_way_reduced("3") == "3.75"
  end

  test "it finds the monthly fare given a zone" do
    assert Repo.monthly("8") == "363.00"
  end

  test "it finds the interzone monthly fare given a zone" do
    assert Repo.monthly("interzone 4") == "130.25"
  end
end
