defmodule Content.FixtureHelpers do
  def fixture(name) do
    [Path.dirname(__ENV__.file), "..", "fixtures", name]
    |> Path.join
    |> File.read!
    |> Poison.decode!
  end
end
