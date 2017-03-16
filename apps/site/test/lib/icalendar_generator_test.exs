defmodule IcalendarGeneratorTest do
  use ExUnit.Case, async: true
  import Content.Factory
  import Content.FactoryHelpers
  alias Site.IcalendarGenerator

  describe "to_ical/1" do
    test "includes the appropriate headers for the iCalendar file format" do
      event = event_page_factory()

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
        event_page_factory()
        |> update_attribute(:body, "<p>Here is a <strong>description</strong></p>.")
        |> update_fields_attribute(:location, "MassDot")
        |> update_fields_attribute(:street_address, "10 Park Plaza")
        |> update_fields_attribute(:city, "Boston")
        |> update_fields_attribute(:state, "MA")

      result =
        IcalendarGenerator.to_ical(event)
        |> IO.iodata_to_binary

      assert result =~ "DESCRIPTION:Here is a description."
      assert result =~ "LOCATION:MassDot 10 Park Plaza Boston, MA"
      assert result =~ "SUMMARY:#{event.title}"
      assert result =~ "URL:http://localhost:4001/events/#{event.id}"
    end

    test "includes unique identifiers for updating an existing calendar event" do
      event = event_page_factory()

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
        event_page_factory()
        |> update_fields_attribute(:start_time, start_datetime)
        |> update_fields_attribute(:end_time, end_datetime)

      result =
        IcalendarGenerator.to_ical(event)
        |> IO.iodata_to_binary

      assert result =~ "DTSTART;TZID=\"America/New_York\":20170228T090000"
      assert result =~ "DTEND;TZID=\"America/New_York\":20170228T110000"
    end

    test "when the event does not have an end time" do
      event =
        event_page_factory()
        |> update_fields_attribute(:end_time, nil)

      result =
        IcalendarGenerator.to_ical(event)
        |> IO.iodata_to_binary

      assert result =~ "DTEND;TZID=\"America/New_York\":\n"
    end
  end
end
