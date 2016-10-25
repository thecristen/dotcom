defmodule AndJoinTest do
  use ExUnit.Case, async: true
  import AndJoin

  test "join/1" do
    assert [] |> join |> collapse == ""
    assert ["1"] |> join |> collapse == "1"
    assert ["1", "2"] |> join |> collapse == "1 and 2"
    assert ["1", "2", "3"] |> join |> collapse == "1, 2, and 3"
    assert ["1", "2", "3", "4"] |> join |> collapse == "1, 2, 3, and 4"
  end

  defp collapse(string) when is_binary(string), do: string
  defp collapse(list) when is_list(list) do
    list
    |> List.flatten
    |> Enum.join("")
  end
end
