defmodule News.RepoTest do
  use ExUnit.Case, async: true

  @post_filename [__DIR__, "fixture", "2016-06-07-post-id.md"] |> Path.join |> Path.expand

  test ".all returns News.Post structs" do
    assert News.Repo.all == [News.Jekyll.parse_file(@post_filename)]
  end

  test ".all can be limited to a number of posts" do
    assert News.Repo.all(limit: 0) == []
  end

  test ".get returns a post by its ID" do
    assert News.Repo.get!(News.Post, "post-id") == News.Jekyll.parse_file(@post_filename)
  end
end
