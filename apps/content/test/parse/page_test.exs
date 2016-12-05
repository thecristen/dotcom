defmodule Content.Parse.PageTest do
  use ExUnit.Case, async: true
  use ExCheck

  describe "parse/1" do
    test "parses a binary into a %Content.Page{}" do
      expected = {:ok, %Content.Page{
                     type: "page",
                     title: "Privacy Policy",
                     body: "<p><strong>MBTA'S WEBSITE AND ELECTRONIC FARE MEDIA PRIVACY POLICY</strong><br />",
                     updated_at: Timex.to_datetime(~N[2016-11-07T15:55:35], "Etc/UTC")}}
      actual = Content.Parse.Page.parse(fixture("page.json"))
      assert actual == expected
    end

    test "parses additional fields" do
      expected = {:ok, %Content.Page{
                     type: "project_update",
                     title: "Government Center Construction",
                     body: "project value\r\n",
                     updated_at: Timex.to_datetime(~N[2016-12-01T17:23:51], "Etc/UTC"),
                     fields: %{
                       status: "Construction",
                       featured_image: %Content.Page.Image{
                         alt: "Alt Text",
                         height: 368,
                         url: "https://drupal-host/sites/default/files/image.png",
                         width: 667},
                       photo_gallery: [
                         %Content.Page.Image{
                           alt: "Photo Gallery",
                           height: 2322,
                           url: "https://drupal-host/sites/default/files/gallery_photo.jpg",
                           width: 4128}
                       ],
                       downloads: [
                         %Content.Page.File{
                           url: "https://drupal-host/sites/default/files/presentation.pdf",
                           description: "Presentation",
                           type: :pdf}
                       ]
                     }}}
      actual = "project.json" |> fixture |> Content.Parse.Page.parse
      assert actual == expected
    end

    property "always returns either {:ok, %Page{}} or {:error, any}" do
      for_all body in unicode_binary do
        result = Content.Parse.Page.parse(body)
        match?({:ok, %Content.Page{}}, result) || match?({:error, _}, result)
      end
    end
  end

  def fixture(name) do
    [Path.dirname(__ENV__.file), "..", "fixtures", name]
    |> Path.join
    |> File.read!
  end
end
