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
    assert List.first(response) == %Schedules.Stop{id: "Lowell", name: "Lowell"}
    assert List.last(response) == %Schedules.Stop{id: "North Station", name: "North Station"}
    assert response == Enum.uniq(response)
  end

  test ".trip returns stops in order of their stop_sequence for a given trip" do
    trip_id = "31174481-CR_MAY2016-hxl16011-Weekday-01"
    response = Schedules.Repo.trip(trip_id)
    assert response |> Enum.all?(fn schedule -> schedule.trip.id == trip_id end)
    assert List.first(response).stop.id == "Lowell"
    assert List.last(response).stop.id == "North Station"
  end
end
