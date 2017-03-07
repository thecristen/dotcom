defmodule Content.MetaDataTest do
  use ExUnit.Case, async: false
  import Mock

  test "for/1 returns meta data for a given page type" do
    with_mock Content.Repo, [page: fn(_) -> {:ok, [%Content.Page{body: "<p>body content</p>"}]} end] do
      assert Content.MetaData.for("news_entry") == %{
        recent_news: [%Content.Page{body: "<p>body content</p>"}]
      }
    end
  end

  test "for/1 returns an empty map given an unknown page type" do
    assert Content.MetaData.for("unknown") == %{}
  end

  test "fetch_recent_news/0 returns a list of news entries" do
    with_mock Content.Repo, [page: fn(_) -> {:ok, ["entry_1, entry_2"]} end] do
      assert Content.MetaData.fetch_recent_news() == ["entry_1, entry_2"]
    end
  end

  test "fetch_recent_news/0, given the request fails, returns an empty array" do
    with_mock Content.Repo, [page: fn(_) -> {:error, "error message"} end] do
      assert Content.MetaData.fetch_recent_news() == []
    end
  end
end
