defmodule Content.Parse.PageTest do
  use ExUnit.Case, async: true
  use ExCheck

  @body __ENV__.file
  |> Path.dirname
  |> Path.join("..")
  |> Path.join("fixtures")
  |> Path.join("page.json")
  |> File.read!

  describe "parse/1" do
    test "parses a binary into a Cotnent.Page struct" do
      expected = {:ok, %Content.Page{
                     title: "Privacy Policy",
                     body: "<p><strong>MBTA'S WEBSITE AND ELECTRONIC FARE MEDIA PRIVACY POLICY</strong><br />",
                     updated_at: Timex.to_datetime(~N[2016-11-07T15:55:35], "Etc/UTC")}}
      actual = Content.Parse.Page.parse(@body)
      assert actual == expected
    end

    property "always returns either {:ok, %Page{}} or {:error, any}" do
      for_all body in unicode_binary do
        result = Content.Parse.Page.parse(body)
        match?({:ok, %Content.Page{}}, result) || match?({:error, _}, result)
      end
    end
  end
end
