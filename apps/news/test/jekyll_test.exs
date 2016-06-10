defmodule News.JekyllTest do
  use ExUnit.Case, async: true

  test ".parse takes a string and turns it into a News.Post" do
    post = """
    ---
category: event
title: Upcoming Bus Replacement Service on The D Line
---
post
body
    """

    assert News.Jekyll.parse(post) == {:ok, %News.Post{
                                          attributes: %{
                                            "category" => "event",
                                            "title" => "Upcoming Bus Replacement Service on The D Line"
                                          },
                                          body: "post\nbody"}}
  end

  test ".parse returns an error if it can't parse the file" do
    assert {:error, _} = News.Jekyll.parse("")
  end

  test ".parse_file includes the date and ID from the filename" do
    filename = Path.join([__DIR__, "fixture", "2016-06-07-post-id.md"])
    assert News.Jekyll.parse_file!(filename) == %News.Post{
      filename: filename,
      id: "post-id",
      date: {2016, 6, 7},
      attributes: %{
        "title" => "from file",
      },
      body: "file body"
    }
  end
end
