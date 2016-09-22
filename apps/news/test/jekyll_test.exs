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

  test ".parse returns an error if the yaml throws an exception" do
    assert {:error, _} = News.Jekyll.parse("""
    ---
homepageicon: <img style="width: 70px; height: 70px;" />
---
    """)
  end
end
