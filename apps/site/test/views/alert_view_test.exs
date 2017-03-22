defmodule Site.AlertViewTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import Phoenix.HTML, only: [safe_to_string: 1]
  import Site.AlertView
  alias Alerts.Alert

  @route %Routes.Route{type: 2, id: "route_id", name: "Name"}

  describe "alert_effects/1" do
    test "returns one alert for one effect" do
      delay_alert = %Alert{effect_name: "Delay", lifecycle: "Upcoming"}

      expected = {"Delay", ""}
      actual = alert_effects([delay_alert], 0)

      assert expected == actual
    end

    test "returns a count with multiple alerts" do
      alerts = [
        %Alert{effect_name: "Suspension", lifecycle: "New"},
        %Alert{effect_name: "Delay"},
        %Alert{effect_name: "Cancellation"}
      ]

      expected = {"Suspension", ["+", "2", " more"]}
      actual = alert_effects(alerts, 0)

      assert expected == actual
    end

    test "returns text when there are no current alerts" do
     assert [] |> alert_effects(0) |> :erlang.iolist_to_binary == "There are no alerts for today."
     assert [] |> alert_effects(1) |> :erlang.iolist_to_binary == "There are no alerts for today; 1 upcoming alert."
     assert [] |> alert_effects(2) |> :erlang.iolist_to_binary == "There are no alerts for today; 2 upcoming alerts."
    end
  end

  describe "effect_name/1" do
    test "returns the effect name for new alerts" do
      assert "Effect" == effect_name(%Alert{effect_name: "Effect", lifecycle: "New"})
    end

    test "includes the lifecycle for alerts" do
      assert "Effect (Upcoming)" == %Alert{effect_name: "Effect", lifecycle: "Upcoming"} |> effect_name |> IO.iodata_to_binary
    end
  end

  describe "alert_updated/1" do
    test "returns the relative offset based on our timezone" do
      now = ~N[2016-10-05T00:02:03]
      date = ~D[2016-10-05]
      alert = %Alert{updated_at: now}

      expected = "Last Updated: Today at 12:02 AM"
      actual = alert |> alert_updated(date) |> :erlang.iolist_to_binary
      assert actual == expected
    end

    test "alerts from further in the past use a date" do
      now = ~N[2016-10-05T00:02:03]
      date = ~D[2016-10-06]

      alert = %Alert{updated_at: now}

      expected = "Last Updated: 10/5/2016 12:02 AM"
      actual = alert |> alert_updated(date) |> :erlang.iolist_to_binary
      assert actual == expected
    end
  end

  describe "clamp_header/1" do
    test "short headers are the same" do
      assert clamp_header("short") == "short"
    end

    test "anything more than 60 characters gets chomped to 60 characters" do
      long = String.duplicate("x", 61)
      assert long |> clamp_header |> :erlang.iolist_to_binary |> String.length == 60
    end

    test "clamps that end in a space have it trimmed" do
      text = String.duplicate(" ", 61)
      assert text |> clamp_header |> :erlang.iolist_to_binary |> String.length == 1
    end
  end

  describe "format_alert_description/1" do
    test "escapes existing HTML" do
      expected = {:safe, "&lt;br&gt;"}
      actual = format_alert_description("<br>")

      assert expected == actual
    end

    test "replaces newlines with breaks" do
      expected = {:safe, "hi<br />there"}
      actual = format_alert_description("hi\nthere")

      assert expected == actual
    end

    test "combines multiple newlines" do
      expected = {:safe, "hi<br />there"}
      actual = format_alert_description("hi\n\n\nthere")

      assert expected == actual
    end

    test "combines multiple Windows newlines" do
      expected = {:safe, "hi<br />there"}
      actual = format_alert_description("hi\r\n\r\nthere")

      assert expected == actual
    end

    test "<strong>ifies a header" do
      expected = {:safe, "hi<br /><strong>Header:</strong><br />7:30"}
      actual = format_alert_description("hi\nHeader:\n7:30")

      assert expected == actual
    end

    test "<strong>ifies a starting long header" do
      expected = {:safe, "<strong>Long Header:</strong><br />7:30"}
      actual = format_alert_description("Long Header:\n7:30")

      assert expected == actual
    end
  end

  describe "modal.html" do
    test "text for no current alerts and 1 upcoming alert" do
      response = Site.AlertView.render("modal.html", alerts: [], upcoming_alert_count: 1, route: @route, time: Util.now)
      text = safe_to_string(response)
      assert text =~ "There are currently no service alerts affecting the #{@route.name} today."
    end

    test "text for no current alerts and 2 upcoming alerts" do
      response = Site.AlertView.render("modal.html", alerts: [], upcoming_alert_count: 2, route: @route, time: Util.now)
      text = safe_to_string(response)
      assert text =~ "There are currently no service alerts affecting the #{@route.name} today."
    end
  end

  describe "inline/2" do
    test "raises an exception if time is not an option" do
      assert catch_error(
        Site.AlertView.inline(Site.Endpoint, [])
      )
    end

    test "renders nothing if no alerts are passed in" do
      result = Site.AlertView.inline(Site.Endpoint,
        alerts: [],
        time: Util.service_date)

      assert result == ""
    end

    test "renders if a list of alerts and times is passed in" do
      result = Site.AlertView.inline(Site.Endpoint,
        alerts: [%Alert{effect_name: "Delay", lifecycle: "Upcoming",
                               updated_at: Util.now}],
        time: Util.service_date)

      refute safe_to_string(result) == ""
    end
  end

  describe "_item.html" do
    @alert %Alert{effect_name: "Access Alert", updated_at: ~D[2017-03-01], header: "Alert Header", description: "description"}
    @time ~N[2017-03-01T07:29:00]

    test "Displays full description button if alert has description" do
      response = Site.AlertView.render("_item.html", alert: @alert, time: @time)
      assert safe_to_string(response) =~ "View Full Description"
    end

    test "Does not display full description button if description is nil" do
      response = Site.AlertView.render("_item.html", alert: %{@alert | description: nil}, time: @time)
      refute safe_to_string(response) =~ "View Full Description"
    end
  end
end
