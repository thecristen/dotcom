defmodule IcalendarGeneratorTest do
  use ExUnit.Case, async: true
  import Content.Factory
  import Phoenix.HTML, only: [raw: 1]
  alias Site.IcalendarGenerator

  describe "to_ical/1" do
    test "includes the appropriate headers for the iCalendar file format" do
      event = event_factory()

      result =
        IcalendarGenerator.to_ical(event)
        |> IO.iodata_to_binary

      assert result =~ "BEGIN:VCALENDAR"
      assert result =~ "VERSION:2.0"
      assert result =~ "PRODID:-//www.mbta.com//Public Meetings//EN"
      assert result =~ "BEGIN:VEVENT"
    end

    test "includes the event details" do
      event =
        event_factory()
        |> Map.put(:body, raw("<p>Here is a <strong>description</strong></p>."))
        |> Map.put(:location, "MassDot")
        |> Map.put(:street_address, "10 Park Plaza")
        |> Map.put(:city, "Boston")
        |> Map.put(:state, "MA")

      result =
        IcalendarGenerator.to_ical(event)
        |> IO.iodata_to_binary

      assert result =~ "DESCRIPTION:Here is a description."
      assert result =~ "LOCATION:MassDot 10 Park Plaza Boston, MA"
      assert result =~ "SUMMARY:#{event.title}"
      assert result =~ "URL:http://localhost:4001/events/#{event.id}"
    end

    test "includes unique identifiers for updating an existing calendar event" do
      event = event_factory()

      result =
        IcalendarGenerator.to_ical(event)
        |> IO.iodata_to_binary

      assert result =~ "UID:event#{event.id}@mbta.com\n"
      assert result =~ "SEQUENCE:"
      refute result =~ "SEQUENCE:\n"
    end

    test "includes the event start and end time with timezone information" do
      start_datetime = Timex.to_datetime({{2017,2,28}, {14, 00, 00}})
      end_datetime = Timex.to_datetime({{2017,2,28}, {16, 00, 00}})

      event =
        event_factory()
        |> Map.put(:start_time, start_datetime)
        |> Map.put(:end_time, end_datetime)

      result =
        IcalendarGenerator.to_ical(event)
        |> IO.iodata_to_binary

      assert result =~ "DTSTART;TZID=\"America/New_York\":20170228T090000"
      assert result =~ "DTEND;TZID=\"America/New_York\":20170228T110000"
    end

    test "when the event does not have an end time" do
      event =
        event_factory()
        |> Map.put(:end_time, nil)

      result =
        IcalendarGenerator.to_ical(event)
        |> IO.iodata_to_binary

      assert result =~ "DTEND;TZID=\"America/New_York\":\n"
    end
  end
end
