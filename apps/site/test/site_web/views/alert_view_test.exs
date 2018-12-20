defmodule SiteWeb.AlertViewTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Timex

  import Phoenix.HTML, only: [safe_to_string: 1, raw: 1]
  import SiteWeb.AlertView
  alias Alerts.Alert

  @route %Routes.Route{type: 2, id: "route_id", name: "Name"}
  @now Util.to_local_time(~N[2018-01-15T12:00:00])

  describe "alert_effects/1" do
    test "returns one alert for one effect" do
      delay_alert = %Alert{effect: :delay, lifecycle: :upcoming}

      expected = {"Delay", ""}
      actual = alert_effects([delay_alert], 0)

      assert expected == actual
    end

    test "returns a count with multiple alerts" do
      alerts = [
        %Alert{effect: :suspension, lifecycle: :new},
        %Alert{effect: :delay},
        %Alert{effect: :cancellation}
      ]

      expected = {"Suspension", ["+", "2", " more"]}
      actual = alert_effects(alerts, 0)

      assert expected == actual
    end

    test "returns text when there are no current alerts" do
      assert [] |> alert_effects(0) |> :erlang.iolist_to_binary() ==
               "There are no alerts for today."

      assert [] |> alert_effects(1) |> :erlang.iolist_to_binary() ==
               "There are no alerts for today; 1 upcoming alert."

      assert [] |> alert_effects(2) |> :erlang.iolist_to_binary() ==
               "There are no alerts for today; 2 upcoming alerts."
    end
  end

  describe "effect_name/1" do
    test "returns the effect name for new alerts" do
      assert "Delay" == effect_name(%Alert{effect: :delay, lifecycle: :new})
    end

    test "includes the lifecycle for alerts" do
      assert "Shuttle" ==
               %Alert{effect: :shuttle, lifecycle: :upcoming}
               |> effect_name
               |> IO.iodata_to_binary()
    end
  end

  describe "route_icon/1" do
    test "silver line icon" do
      icon =
        %Routes.Route{
          description: :rapid_transit,
          direction_names: %{0 => "Outbound", 1 => "Inbound"},
          id: "742",
          long_name: "Design Center - South Station",
          name: "SL2",
          type: 3
        }
        |> route_icon()
        |> safe_to_string()

      icon =~ "Silver Line"
    end

    test "red line icon" do
      icon =
        %Routes.Route{
          description: :rapid_transit,
          direction_names: %{0 => "Southbound", 1 => "Northbound"},
          id: "Red",
          long_name: "Red Line",
          name: "Red Line",
          type: 1
        }
        |> route_icon()
        |> safe_to_string()

      icon =~ "Red Line"
    end
  end

  describe "alert_updated/1" do
    test "returns the relative offset based on our timezone" do
      now = ~N[2016-10-05T00:02:03]
      date = ~D[2016-10-05]
      alert = %Alert{updated_at: now}

      expected = "Last Updated: Today at 12:02A"
      actual = alert |> alert_updated(date) |> :erlang.iolist_to_binary()
      assert actual == expected
    end

    test "alerts from further in the past use a date" do
      now = ~N[2016-10-05T00:02:03]
      date = ~D[2016-10-06]

      alert = %Alert{updated_at: now}

      expected = "Last Updated: 10/5/2016 12:02A"
      actual = alert |> alert_updated(date) |> :erlang.iolist_to_binary()
      assert actual == expected
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

    test "linkifies a URL" do
      expected =
        raw(~s(before <a target="_blank" href="http://mbta.com">http://mbta.com</a> after))

      actual = format_alert_description("before http://mbta.com after")

      assert expected == actual
    end
  end

  describe "replace_urls_with_links/1" do
    test "does not include a period at the end of the URL" do
      expected =
        raw(~s(<a target="_blank" href="http://mbta.com/foo/bar">http://mbta.com/foo/bar</a>.))

      actual = replace_urls_with_links("http://mbta.com/foo/bar.")

      assert expected == actual
    end

    test "can replace multiple URLs" do
      expected = raw(~s(<a target="_blank" href="http://one.com">http://one.com</a> \
<a target="_blank" href="https://two.net">https://two.net</a>))
      actual = replace_urls_with_links("http://one.com https://two.net")

      assert expected == actual
    end

    test "adds http:// to the URL if it's missing" do
      expected = raw(~s(<a target="_blank" href="http://http.com">http.com</a>))
      actual = replace_urls_with_links("http.com")

      assert expected == actual
    end

    test "does not link short TLDs" do
      expected = raw("a.m.")
      actual = replace_urls_with_links("a.m.")
      assert expected == actual
    end
  end

  describe "group.html" do
    test "text for no current alerts and 1 upcoming alert" do
      response =
        render(
          "group.html",
          alerts: [],
          upcoming_alert_count: 1,
          route: @route,
          time: Util.now()
        )

      text = safe_to_string(response)
      assert text =~ "There are currently no service alerts affecting the #{@route.name} today."
    end

    test "text for no alerts of any type but show_empty? set" do
      response =
        group(
          alerts: [],
          route: @route,
          stop?: true,
          show_empty?: true
        )

      text = safe_to_string(response)
      assert text =~ "Service is running as expected at Name. There are no alerts at this time."
    end

    test "text for no current alerts and 2 upcoming alerts" do
      response =
        render(
          "group.html",
          alerts: [],
          upcoming_alert_count: 2,
          route: @route,
          time: Util.now()
        )

      text = safe_to_string(response)
      assert text =~ "There are currently no service alerts affecting the #{@route.name} today."
    end
  end

  describe "inline/2" do
    test "raises an exception if time is not an option" do
      assert catch_error(inline(SiteWeb.Endpoint, []))
    end

    test "renders nothing if no alerts are passed in" do
      result =
        inline(
          SiteWeb.Endpoint,
          alerts: [],
          time: Util.service_date()
        )

      assert result == ""
    end

    test "renders if a list of alerts and times is passed in" do
      result =
        inline(
          SiteWeb.Endpoint,
          alerts: [%Alert{effect: :delay, lifecycle: :upcoming, updated_at: Util.now()}],
          time: Util.service_date()
        )

      refute safe_to_string(result) == ""
    end
  end

  describe "_item.html" do
    @alert %Alert{
      effect: :access_issue,
      updated_at: ~D[2017-03-01],
      header: "Alert Header",
      description: "description"
    }
    @time ~N[2017-03-01T07:29:00]
    @active_period [{Timex.shift(@now, days: -8), Timex.shift(@now, days: 8)}]

    test "Displays expansion control if alert has description" do
      response = render("_item.html", alert: @alert, time: @time)
      assert safe_to_string(response) =~ "m-alert-item__caret--up"
    end

    test "Does not display expansion control if description is nil" do
      response = render("_item.html", alert: %{@alert | description: nil}, time: @time)

      refute safe_to_string(response) =~ "m-alert-item__caret--up"
    end

    test "Icons and labels are displayed for shuttle today" do
      response =
        "_item.html"
        |> render(
          alert: %Alert{
            effect: :shuttle,
            lifecycle: :ongoing,
            severity: 7,
            priority: :high
          },
          time: @now
        )
        |> safe_to_string()

      assert response =~ "c-svg__icon-shuttle-default"
      assert response =~ "m-alert-item__badge"
    end

    test "Icons and labels are displayed for delay" do
      response =
        "_item.html"
        |> render(
          alert: %Alert{
            effect: :delay,
            priority: :high
          },
          time: @now
        )
        |> safe_to_string()

      assert response =~ "c-svg__icon-alerts-triangle"
      assert response =~ "up to 20 minutes"
    end

    test "Icons and labels are displayed for snow route" do
      response =
        "_item.html"
        |> render(
          alert: %Alert{
            effect: :snow_route,
            lifecycle: :ongoing,
            severity: 7,
            priority: :high
          },
          time: @now
        )
        |> safe_to_string()

      assert response =~ "c-svg__icon-snow-default"
      assert response =~ "Ongoing"
    end

    test "Icons and labels are displayed for cancellation" do
      response =
        render(
          "_item.html",
          alert: %Alert{
            effect: :cancellation,
            active_period: @active_period,
            priority: :high
          },
          time: @now
        )

      assert safe_to_string(response) =~ "c-svg__icon-cancelled-default"
    end

    test "No icon for future cancellation" do
      response =
        "_item.html"
        |> render(
          alert: %Alert{
            effect: :cancellation,
            active_period: @active_period,
            lifecycle: :upcoming,
            priority: :low
          },
          time: @time
        )
        |> safe_to_string()

      refute response =~ "c-svg__icon"
      assert response =~ "Upcoming"
    end
  end

  test "mode_buttons" do
    assert [subway | rest] =
             :subway
             |> mode_buttons()
             |> Enum.map(&safe_to_string/1)

    assert subway =~ "m-alerts__mode-button--selected"

    for mode <- rest do
      refute mode =~ "m-alerts__mode-button--selected"
    end
  end
end
