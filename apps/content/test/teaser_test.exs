defmodule Content.TeaserTest do
  use ExUnit.Case, async: true
  alias Content.CMS.Static
  alias Content.Teaser

  test "parses a teaser item into %Content.Teaser{}" do
    [raw | _] = Static.teasers_response()
    teaser = Teaser.from_api(raw)

    assert %Teaser{
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
      Static.teasers_response()
      |> List.first()
      |> Map.put("type", "news_entry")
      |> Map.put("changed", "2018-10-18")
      |> Map.put("posted", "2018-10-25")

    teaser = Teaser.from_api(raw)
    assert teaser.date.day == 25
  end

  test "sets date to null if date is invalid" do
    assert Static.teasers_response()
           |> List.last()
           |> Map.put("changed", "invalid")
           |> Teaser.from_api()
           |> Map.get(:date) == nil
  end

  test "uses updated field as date for projects" do
    assert Static.teasers_response()
           |> List.first()
           |> Teaser.from_api()
           |> Map.get(:date) == ~D[2018-10-10]
  end

  test "uses changed field as date for project when updated is blank" do
    assert Static.teasers_response()
           |> Enum.at(1)
           |> Teaser.from_api()
           |> Map.get(:date) == ~D[2018-10-04]
  end
end
