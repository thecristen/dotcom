defmodule Content.TeaserTest do
  use ExUnit.Case, async: true

  test "parses a teaser item into %Content.Teaser{}" do
    [raw | _] = Content.CMS.Static.teasers_response()
    teaser = Content.Teaser.from_api(raw)
    assert %Content.Teaser{
      type: type,
      path: path,
      image_path: image,
      text: text,
      title: title,
      date: date,
      topic: topic
    } = teaser

    assert type == :project
    assert path == "/projects/green-line-d-track-and-signal-replacement"
    assert "http://" <> _ = image
    assert text =~ "This project is part of"
    assert title == "Green Line D Track and Signal Replacement"
    assert topic == ""
    assert %Date{} = date
  end

  test "uses field_posted_on date for news entries" do
    raw =
      Content.CMS.Static.teasers_response()
      |> List.first()
      |> Map.put("type", "news_entry")
      |> Map.put("changed", "2018-10-18")
      |> Map.put("field_posted_on", "2018-10-25")

    teaser = Content.Teaser.from_api(raw)
    assert teaser.date.day == 25
  end

  test "sets date to null if date is invalid" do
    assert Content.CMS.Static.teasers_response()
           |> List.first()
           |> Map.put("changed", "invalid")
           |> Content.Teaser.from_api()
           |> Map.get(:date) == nil
  end
end
