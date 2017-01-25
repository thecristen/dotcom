defmodule TripInfo.SplitTest do
  use ExUnit.Case, async: true
  use ExCheck
  import TripInfo.Split

  @origin_id "origin"
  @destination_id "destination"
  @vehicle_id "vehicle"

  defp time(stop_id \\ nil) do
    %Schedules.Schedule{stop: %Schedules.Stop{id: stop_id}}
  end

  test "splits into three sections if the vehicle is before the origin and we'd remove 3 stops" do
    times = [
      time(@vehicle_id),
      time("with_vehicle"),
      time(),
      time(),
      time(),
      time(@origin_id),
      time("with_origin"),
      time(),
      time(),
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
      time(),
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
      time(),
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
      time(),
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

  test "keeps the origin and destination in a single section if they're separated by three" do
    times = [
      time(@vehicle_id),
      time("with_vehicle"),
      time(),
      time(),
      time(),
      time(@origin_id),
      time("with_origin"),
      time("between_origin_destination"),
      time("with_destination"),
      time(@destination_id)
    ]
    actual = split(times, [@origin_id, @vehicle_id])
    expected = [
      [time(@vehicle_id), time("with_vehicle")],
      [time(@origin_id), time("with_origin"), time("between_origin_destination"), time("with_destination"), time(@destination_id)]
    ]
    assert actual == expected
  end

  test "keeps starting IDs together if they're adjacent" do
    times = [
      time(@vehicle_id),
      time(@origin_id),
      time("with_origin"),
      time(),
      time(),
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
      time(),
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

  test "keeps starting IDs together if they are separated by two" do
    times = [
      time(@vehicle_id),
      time("between_vehicle_origin"),
      time("between_vehicle_origin"),
      time(@origin_id),
      time("with_origin"),
      time(),
      time(),
      time(),
      time("with_destination"),
      time(@destination_id)
    ]
    actual = split(times, [@origin_id, @vehicle_id])
    expected = [
      [time(@vehicle_id), time("between_vehicle_origin"), time("between_vehicle_origin"), time(@origin_id), time("with_origin")],
      [time("with_destination"), time(@destination_id)]
    ]
    assert actual == expected
  end

  test "keeps starting IDs together if they are separated by three" do
    times = [
      time(@vehicle_id),
      time("with_vehicle"),
      time("between_vehicle_origin"),
      time("before_origin"),
      time(@origin_id),
      time("with_origin"),
      time(),
      time(),
      time(),
      time("with_destination"),
      time(@destination_id)
    ]
    actual = split(times, [@origin_id, @vehicle_id])
    expected = [
      [time(@vehicle_id), time("with_vehicle"), time("between_vehicle_origin"), time("before_origin"), time(@origin_id), time("with_origin")],
      [time("with_destination"), time(@destination_id)]
    ]
    assert actual == expected
  end

  test "order of the starting IDs does not matter" do
    times = [
      time(@origin_id),
      time("with_origin"),
      time(),
      time(),
      time(),
      time(@vehicle_id),
      time("with_vehicle"),
      time(),
      time(),
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
      time(),
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
    for number_between <- 0..3 do
      times = Enum.concat([
        [time(@origin_id)],
        List.duplicate(time("between"), number_between),
        [time(@destination_id)]
      ])
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

  property :split do
    possible_middle_ids = [@origin_id, @vehicle_id, nil]
    for_all {first_extra, second_extra, middle_id} in {non_neg_integer(), non_neg_integer(), elements(possible_middle_ids)} do
      times = Enum.concat([
        [time(@origin_id)],
        List.duplicate(time(), first_extra),
        [time(middle_id)],
        List.duplicate(time(), second_extra),
        [time(@destination_id)]
      ])
      actual = split(times, [@origin_id, @vehicle_id])
      actual_count = length(actual)
      expected_count = cond do
        is_nil(middle_id) and first_extra + second_extra < 4 ->
          # no middle ID, and fewer than 4 extras means we collapse due to
          # hiding fewer than 3 stops
          1
        is_nil(middle_id) ->
          # no middle ID and enough extra means a first section and end section
          2
        first_extra > 3 and second_extra > 4 ->
          # more than three on start side and more than 4 on second: 3 sections
          3
        first_extra > 3 or second_extra > 4 ->
          # enough on only one side, collapse into two sections
          2
        true ->
          # not collapsing
          1
      end
      actual_count == expected_count
    end
  end
end
