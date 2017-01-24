defmodule TripInfo.SplitTest do
  use ExUnit.Case, async: true
  import TripInfo.Split

  @origin_id "origin"
  @destination_id "destination"
  @vehicle_id "vehicle"

  defp time(stop_id \\ nil) do
    %Schedules.Schedule{stop: %Schedules.Stop{id: stop_id}}
  end

  test "splits into three sections if the vehicle is before the origin" do
    times = [
      time(@vehicle_id),
      time("with_vehicle"),
      time(),
      time(@origin_id),
      time("with_origin"),
      time(),
      time("with_destination"),
      time(@destination_id)
    ]
    actual = split(times, [@origin_id, @vehicle_id])
    expected = [
      [time(@vehicle_id), time("with_vehicle")],
      [time(@origin_id), time("with_origin")],
      [time("with_destination"), time(@destination_id)]
    ]
    assert actual == expected
  end

  test "keeps the origin and destination in a single section if they're adjacent" do
    times = [
      time(@vehicle_id),
      time("with_vehicle"),
      time(),
      time(@origin_id),
      time(@destination_id)
    ]
    actual = split(times, [@origin_id, @vehicle_id])
    expected = [
      [time(@vehicle_id), time("with_vehicle")],
      [time(@origin_id), time(@destination_id)]
    ]
    assert actual == expected
  end

  test "keeps the origin and destination in a single section if they're separated by one" do
    times = [
      time(@vehicle_id),
      time("with_vehicle"),
      time(),
      time(@origin_id),
      time("between_origin_destination"),
      time(@destination_id)
    ]
    actual = split(times, [@origin_id, @vehicle_id])
    expected = [
      [time(@vehicle_id), time("with_vehicle")],
      [time(@origin_id), time("between_origin_destination"), time(@destination_id)]
    ]
    assert actual == expected
  end

  test "keeps the origin and destination in a single section if they're separated by two" do
    times = [
      time(@vehicle_id),
      time("with_vehicle"),
      time(),
      time(@origin_id),
      time("with_origin"),
      time("with_destination"),
      time(@destination_id)
    ]
    actual = split(times, [@origin_id, @vehicle_id])
    expected = [
      [time(@vehicle_id), time("with_vehicle")],
      [time(@origin_id), time("with_origin"), time("with_destination"), time(@destination_id)]
    ]
    assert actual == expected
  end

  test "keeps starting IDs together if they're adjacent" do
    times = [
      time(@vehicle_id),
      time(@origin_id),
      time("with_origin"),
      time(),
      time("with_destination"),
      time(@destination_id)
    ]
    actual = split(times, [@origin_id, @vehicle_id])
    expected = [
      [time(@vehicle_id), time(@origin_id), time("with_origin")],
      [time("with_destination"), time(@destination_id)]
    ]
    assert actual == expected
  end

  test "keeps starting IDs together if they are separated by one" do
    times = [
      time(@vehicle_id),
      time("between_vehicle_origin"),
      time(@origin_id),
      time("with_origin"),
      time(),
      time("with_destination"),
      time(@destination_id)
    ]
    actual = split(times, [@origin_id, @vehicle_id])
    expected = [
      [time(@vehicle_id), time("between_vehicle_origin"), time(@origin_id), time("with_origin")],
      [time("with_destination"), time(@destination_id)]
    ]
    assert actual == expected
  end

  test "order of the starting IDs does not matter" do
    times = [
      time(@origin_id),
      time("with_origin"),
      time(),
      time(@vehicle_id),
      time("with_vehicle"),
      time(),
      time("with_destination"),
      time(@destination_id)
    ]
    actual = split(times, [@origin_id, @vehicle_id])
    expected = [
      [time(@origin_id), time("with_origin")],
      [time(@vehicle_id), time("with_vehicle")],
      [time("with_destination"), time(@destination_id)]
    ]
    assert actual == expected
  end

  test "if there's only one starting ID, only break into two sections" do
    times = [
      time(@origin_id),
      time("with_origin"),
      time(),
      time("with_destination"),
      time(@destination_id)
    ]
    actual = split(times, [@origin_id])
    expected = [
      [time(@origin_id), time("with_origin")],
      [time("with_destination"), time(@destination_id)]
    ]
    assert actual == expected
  end

  test "if there are too few trips, does not break into sections" do
    for times <- [
          [time(@origin_id), time(@destination_id)],
          [time(@origin_id), time("between_origin_destination"), time(@destination_id)],
          [time(@origin_id), time("with_origin"), time("with_destination"), time(@destination_id)]] do
        actual = split(times, [@origin_id])
        expected = [times]
        assert actual == expected
    end
  end

  test "if there are no trips, return no sections" do
    actual = split([], [@origin_id])
    expected = []
    assert actual == expected
  end
end
