defmodule Content.Parse.PageTest do
  use ExUnit.Case, async: true

  describe "parse/1" do
    test "parses a binary into a Cotnent.Page struct" do
      body = __ENV__.file
      |> Path.dirname
      |> Path.join("..")
      |> Path.join("fixtures")
      |> Path.join("page.json")
      |> File.read!

      expected = {:ok, %Content.Page{
                     title: "Privacy Policy",
                     body: "<p><strong>MBTA'S WEBSITE AND ELECTRONIC FARE MEDIA PRIVACY POLICY</strong><br />",
                     updated_at: Timex.to_datetime(~N[2016-11-07T15:55:35], "Etc/UTC")}}
      actual = Content.Parse.Page.parse(body)
      assert actual == expected
    end
  end
end
