defmodule Content.Parse.PageTest do
  use ExUnit.Case, async: true
  use ExCheck

  import Content.Parse.Page

  describe "parse/1" do
    test "parses a binary into a %Content.Page{}" do
      expected = {:ok, %Content.Page{
                     type: "page",
                     id: "1",
                     title: "Privacy Policy",
                     body: "<p><strong>MBTA'S WEBSITE AND ELECTRONIC FARE MEDIA PRIVACY POLICY</strong><br />",
                     updated_at: Timex.to_datetime(~N[2016-11-07T15:55:35], "Etc/UTC")}}
      actual = "page.json" |> fixture |> parse
      assert actual == expected
    end

    test "parses project pages" do
      expected = {:ok, %Content.Page{
                     type: "project_update",
                     id: "3",
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
      actual = "project.json" |> fixture |> parse
      assert actual == expected
    end

    test "parses news pages" do
      expected = {:ok, %Content.Page{
                     type: "news_entry",
                     id: "3",
                     title: "Government Center Construction",
                     body: "project value\r\n",
                     updated_at: Timex.to_datetime(~N[2016-12-01T17:23:51], "Etc/UTC"),
                     fields: %{
                       media_contact: "MassDOT",
                       media_phone: "(123) 456-7890",
                       featured_image: %Content.Page.Image{
                         alt: "Alt Text",
                         height: 368,
                         url: "https://drupal-host/sites/default/files/image.png",
                         width: 667}
                     }}}
      actual = "news.json" |> fixture |> parse
      assert actual == expected
    end

    test "parses event pages" do
      expected = {:ok, %Content.Page{
                     type: "event",
                     id: "3",
                     title: "Board Meeting",
                     body: "project value\r\n",
                     updated_at: Timex.to_datetime(~N[2016-12-01T17:23:51], "Etc/UTC"),
                     fields: %{
                       start_time: Timex.to_datetime(~N[2016-11-14T17:00:00], "Etc/UTC")
                     }}}
      actual = "event.json" |> fixture |> parse
      assert actual == expected
    end

    test "parses list of pages" do
      body = ~s([#{fixture("event.json")},#{fixture("news.json")}])
      {:ok, event} = "event.json" |> fixture |> parse
      {:ok, news} = "news.json" |> fixture |> parse
      expected = {:ok, [event, news]}
      actual = body |> parse
      assert actual == expected
    end

    test "returns error if it's unable to parse the list" do
      body = ~s([#{fixture("news.json")}, {}, {}])
      actual = body |> parse
      assert {:error, _} = actual
    end

    property "always returns either {:ok, %Page{}} or {:error, any}" do
      for_all body in unicode_binary() do
        result = parse(body)
        match?({:ok, %Content.Page{}}, result) || match?({:error, _}, result)
      end
    end
  end

  describe "parse_field_end_time/1" do
    test "returns nil if there's no value" do
      assert parse_field_end_time([]) == [end_time: nil]
    end

    test "returns a UTC datetime if it's valid" do
      assert parse_field_end_time([%{"value" => "2016-01-01T00:00:00"}]) ==
        [end_time: Timex.to_datetime(~N[2016-01-01T00:00:00], "Etc/UTC")]
    end

    test "returns nothing if the time is invalid" do
      assert parse_field_end_time([%{"value" => "not a time"}]) == []
    end
  end

  def fixture(name) do
    [Path.dirname(__ENV__.file), "..", "fixtures", name]
    |> Path.join
    |> File.read!
  end
end
