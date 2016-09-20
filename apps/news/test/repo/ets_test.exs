defmodule News.Repo.EtsTest do
  use ExUnit.Case, async: true
  alias News.Repo.Ets

  setup _ do
    Ets.start_link()
    :ok
  end

  test "starts empty" do
    assert [] == Ets.all_ids()
    assert {:error, _} = Ets.get("unknown")
  end

  test "given an update, can return files by filename" do
    Ets.update([{"filename", "contents"}])
    assert ["filename"] == Ets.all_ids
    assert {:ok, "contents"} == Ets.get("filename")
  end
end
