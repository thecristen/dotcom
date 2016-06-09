defmodule Schedules.RepoTest do
  use ExUnit.Case, async: true
  use Timex

  test ".all can take a route/direction/sequence/date" do
    response = Schedules.Repo.all(
      route: 'CR-Lowell',
      date: Date.now,
      direction_id: 1,
      stop_sequence: 1)
    assert response != []
    assert %Schedules.Schedule{} = List.first(response)
  end

  test ".stops returns a list of stops in order of their stop_sequence" do
    response = Schedules.Repo.stops(
      route: 'CR-Lowell',
      date: Date.now,
      direction_id: 1)

    assert response != []
    assert List.first(response) == %Schedules.Stop{id: "Anderson/ Woburn", name: "Anderson/ Woburn"}
    assert List.last(response) == %Schedules.Stop{id: "Winchester Center", name: "Winchester Center"}
    assert response == Enum.uniq(response)
  end
end
