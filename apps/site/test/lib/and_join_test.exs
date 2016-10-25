defmodule AndJoinTest do
  use ExUnit.Case, async: true
  import AndJoin
  import IO, only: [iodata_to_binary: 1]

  test "join/1" do
    assert [] |> join |> iodate_to_binary == ""
    assert ["1"] |> join |> iodate_to_binary == "1"
    assert ["1", "2"] |> join |> iodate_to_binary == "1 and 2"
    assert ["1", "2", "3"] |> join |> iodate_to_binary == "1, 2, and 3"
    assert ["1", "2", "3", "4"] |> join |> iodate_to_binary == "1, 2, 3, and 4"
  end
end
