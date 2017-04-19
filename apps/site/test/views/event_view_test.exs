defmodule Site.EventViewTest do
  use Site.ViewCase, async: true
  import Site.EventView

  describe "index.html" do
    test "includes links to the previous and next month", %{conn: conn} do
      html =
        Site.EventView
        |> render_to_string(
          "index.html",
          conn: conn,
          events: [],
          month: "2017-01-15"
        )

      assert html =~ "<a href=\"/events?month=2016-12-01\">"
      assert html =~ "<a href=\"/events?month=2017-02-01\">"
    end
  end

  describe "show.html" do
    test "the notes section is not rendered when the event notes are empty", %{conn: conn} do
      event =
        event_factory()
        |> Map.put(:notes, nil)

      html =
        Site.EventView
        |> render_to_string("show.html", conn: conn, event: event)

      refute html =~ "Notes"
    end

    test "the agenda section is not renderd when the event agenda is empty", %{conn: conn} do
      event =
        event_factory()
        |> Map.put(:agenda, nil)

      html =
        Site.EventView
        |> render_to_string("show.html", conn: conn, event: event)

      refute html =~ "Agenda"
    end

    test "the location field takes priority over the imported address", %{conn: conn} do
      event =
        event_factory()
        |> Map.put(:location, "MassDot")
        |> Map.put(:imported_address, "Meet me at the docks")

      html =
        Site.EventView
        |> render_to_string("show.html", conn: conn, event: event)

      assert html =~ event.location
      refute html =~ "Meet me at the docks"
    end

    test "given the location field is empty, the imported address is shown", %{conn: conn} do
      event =
        event_factory()
        |> Map.put(:location, nil)
        |> Map.put(:imported_address, "Meet me at the docks")

      html =
        Site.EventView
        |> render_to_string("show.html", conn: conn, event: event)

      assert html =~ "Meet me at the docks"
    end
  end

  describe "calendar_title/1" do
    test "returns the name of the month" do
      params = %{"month" => "2017-01-01"}
      assert calendar_title(params) == "January"
    end

    test "returns default title when a month is not provided" do
      assert calendar_title(%{}) == "Upcoming Meetings"
    end

    test "returns default title given an invalid month" do
      params = %{"month" => "2017-01"}
      assert calendar_title(params) == "Upcoming Meetings"
    end
  end

  describe "no_results_message/1" do
    test "includes the name of the month" do
      params = %{"month" => "2017-01-01"}
      expected_message = "Sorry, there are no meetings in January."

      assert no_results_message(params) == expected_message
    end

    test "displays the default message when a month is not provided" do
      expected_message = "Sorry, there are no upcoming meetings."

      assert no_results_message(%{}) == expected_message
    end

    test "displays the default message given an invalid month" do
      params = %{"month" => "2017-01"}
      expected_message = "Sorry, there are no upcoming meetings."

      assert no_results_message(params) == expected_message
    end
  end

  describe "event_duration/2" do
    test "with no end time, only renders start time" do
      actual = event_duration(~N[2016-11-15T10:00:00], nil)
      expected = "November 15, 2016 10:00 AM"
      assert expected == actual
    end

    test "with start/end on same day, only renders date once" do
      actual = event_duration(~N[2016-11-14T12:00:00], ~N[2016-11-14T14:30:00])
      expected = "November 14, 2016 12:00 PM until 2:30 PM"
      assert expected == actual
    end

    test "with start/end on different days, renders both dates" do
      actual = event_duration(~N[2016-11-14T12:00:00], ~N[2016-12-01T14:30:00])
      expected = "November 14, 2016 12:00 PM until December 1, 2016 2:30 PM"
      assert expected == actual
    end

    test "with DateTimes, shifts them to America/New_York" do
      actual = event_duration(
                              Timex.to_datetime(~N[2016-11-05T05:00:00], "Etc/UTC"),
                              Timex.to_datetime(~N[2016-11-06T06:00:00], "Etc/UTC"))
      # could also be November 6th, 1:00 AM
      expected = "November 5, 2016 1:00 AM until November 6, 2016 2:00 AM"
      assert expected == actual
    end
  end

  describe "shift_date_range/2" do
    test "shifts the month by the provided value" do
      assert shift_date_range("2017-04-15", -1) == "2017-03-01"
    end

    test "returns the beginning of the month" do
      assert shift_date_range("2017-04-15", 1) == "2017-05-01"
    end
  end

  describe "city_and_state" do
    test "returns the city and state, separated by a comma" do
      event =
        event_factory()
        |> Map.put(:city, "Charleston")
        |> Map.put(:state, "South Carolina")

      assert city_and_state(event) == "Charleston, South Carolina"
    end

    test "when the city is not provided" do
      event =
        event_factory()
        |> Map.put(:city, nil)

      assert city_and_state(event) == nil
    end

    test "when the state is not provided" do
      event =
        event_factory()
        |> Map.put(:state, nil)

      assert city_and_state(event) == nil
    end
  end
end
