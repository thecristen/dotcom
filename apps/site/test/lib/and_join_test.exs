defmodule AndJoinTest do
  use ExUnit.Case, async: true
  import AndJoin
  import IO, only: [iodata_to_binary: 1]

  test "and_join/1" do
    assert [] |> and_join |> iodata_to_binary == ""
    assert ["1"] |> and_join |> iodata_to_binary == "1"
    assert ["1", "2"] |> and_join |> iodata_to_binary == "1 and 2"
    assert ["1", "2", "3"] |> and_join |> iodata_to_binary == "1, 2, and 3"
    assert ["1", "2", "3", "4"] |> and_join |> iodata_to_binary == "1, 2, 3, and 4"
  end
end
