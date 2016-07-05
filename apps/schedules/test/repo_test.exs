defmodule Schedules.RepoTest do
  use ExUnit.Case, async: true
  use Timex

  test ".all can take a route/direction/sequence/date" do
    response = Schedules.Repo.all(
      route: "CR-Lowell",
      date: Date.now,
      direction_id: 1,
      stop_sequence: "first")
    assert response != []
    assert %Schedules.Schedule{} = List.first(response)
  end

  test ".all returns the parent station as the stop" do
    response = Schedules.Repo.all(
      route: "Red",
      date: Date.now,
      direction_id: 0,
      stop_sequence: "first")
    assert response != []
    assert %Schedules.Stop{id: "place-alfcl", name: "Alewife"} == List.first(response).stop
  end

  test ".stops returns a list of stops in order of their stop_sequence" do
    response = Schedules.Repo.stops(
      "CR-Lowell",
      date: Date.now,
      direction_id: 1)

    assert response != []
    assert List.first(response) == %Schedules.Stop{id: "Lowell", name: "Lowell"}
    assert List.last(response) == %Schedules.Stop{id: "place-north", name: "North Station"}
    assert response == Enum.uniq(response)
  end

  test ".stops uses the parent station name" do
    response = Schedules.Repo.stops(
      "Green-B",
      date: Date.now,
      direction_id: 0)

    assert response != []
    assert List.first(response) == %Schedules.Stop{id: "place-pktrm", name: "Park Street"}
  end

  test ".trip returns stops in order of their stop_sequence for a given trip" do
    trip_id = "31174481-CR_MAY2016-hxl16011-Weekday-01"
    response = Schedules.Repo.trip(trip_id)
    assert response |> Enum.all?(fn schedule -> schedule.trip.id == trip_id end)
    assert List.first(response).stop.id == "Lowell"
    assert List.last(response).stop.id == "place-north"
  end

  test ".origin_destination returns pairs of Schedule items" do
    today = Date.today |> Timex.format!("{ISOdate}")
    response = Schedules.Repo.origin_destination("Anderson/ Woburn", "North Station",
      date: today, direction_id: 1)
    [{origin, dest}|_] = response

    assert origin.stop.id == "Anderson/ Woburn"
    assert dest.stop.id == "place-north"
    assert origin.trip.id == dest.trip.id
    assert origin.time < dest.time
  end
end
