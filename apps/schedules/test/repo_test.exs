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
end
