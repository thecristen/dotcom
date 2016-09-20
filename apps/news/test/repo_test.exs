defmodule News.RepoTest do
  use ExUnit.Case, async: true
  alias News.{Jekyll, Repo}

  @post_filename [__DIR__, "fixture", "2016-06-07-post-id.md"] |> Path.join |> Path.expand

  test ".all returns Post structs" do
    {:ok, post} = @post_filename |> File.read! |> Jekyll.parse
    post = put_in post.id, "post-id"
    assert Repo.all == [post]
  end

  test ".all can be limited to a number of posts" do
    assert Repo.all(limit: 0) == []
    assert length(Repo.all(limit: 1)) == 1
  end
end
