defmodule SiteWeb.ModeViewTest do
  use ExUnit.Case, async: true

  alias SiteWeb.ModeView
  alias Routes.Route
  alias Alerts.Alert
  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "fares_note/1" do
    test "Commuter Rail has note" do
      commuter_note = ModeView.fares_note("Commuter Rail")
      refute safe_to_string(commuter_note) == ""
      assert ModeView.fares_note("Ferry") == ""
    end
  end

  describe "mode_group_header/3" do
    test "renders an h2 if is_homepage? == false" do
      assert {tag, _, _} =
        :commuter_rail
        |> ModeView.mode_group_header("/schedules/commuter-rail", false)
        |> safe_to_string()
        |> Floki.parse()
      assert tag == "h2"
    end

    test "renders an h3 if is_homepage? == true" do
      assert {tag, _, _} =
        :commuter_rail
        |> ModeView.mode_group_header("/schedules/commuter-rail", true)
        |> safe_to_string()
        |> Floki.parse()
      assert tag == "h3"
    end

    test "sets name and link for mode" do
      modes = [
        {:bus, "Bus", "/schedules/bus"},
        {:commuter_rail, "Commuter Rail", "/schedules/commuter-rail"},
        {:subway, "Subway", "/schedules/subway"},
        {:ferry, "Ferry", "/schedules/ferry"},
        {:the_ride, "The RIDE", "/accessibility/the-ride"},
      ]
      for {mode, text, href} <- modes do
        header =
          mode
          |> ModeView.mode_group_header(href, false)
          |> safe_to_string()

        assert header
               |> Floki.find(".m-mode__name")
               |> Floki.text()
               |> String.trim() == text
        assert header
               |> Floki.find(".m-mode__name")
               |> Floki.attribute("href") == [href]

        view_all = Floki.find(header, ".m-mode__view-all")

        if mode === :bus do
          assert Floki.attribute(view_all, "href") == [href]
          assert Floki.text(view_all) == "View all bus routes"
        else
          assert view_all == []
        end
      end
    end
  end

  describe "has_alert?/3" do
    test "returns true if route has an alert" do
      now = Util.now()
      entity = %Alerts.InformedEntity{route_type: 0, route: "Pink"}
      alert = Alert.new(
        active_period: [{Timex.shift(now, hours: -3), Timex.shift(now, hours: 3)}],
        effect: :delay,
        informed_entity: [entity]
      )

      assert Alerts.Alert.is_notice?(alert, now) == false
      assert Alerts.Match.match([alert], entity, now) == [alert]

      assert ModeView.has_alert?(%Route{id: "Pink", type: 0}, [alert], now) == true
    end
  end

  test "returns false if route does not have an alert" do
      now = Util.now()
      entity = %Alerts.InformedEntity{route_type: 0, route: "Pink"}
      alert = Alert.new(
        active_period: [{Timex.shift(now, days: 5), Timex.shift(now, days: 9)}],
        effect: :service_change,
        informed_entity: [entity]
      )

      assert Alerts.Alert.is_notice?(alert, now) == true
      assert Alerts.Match.match([alert], entity, now) == []

      assert ModeView.has_alert?(%Route{id: "Pink", type: 0}, [alert], now) == false
  end

  describe "bus_filter_atom/1 and bus_filter_range/2" do
    @bus_routes [%Route{name: "SL1"}, %Route{name: "CT1"}, %Route{name: "99"}]

    test "Silver Line and Cross Town" do
      assert [%Route{name: "SL1"}] == Enum.filter(@bus_routes, ModeView.bus_filter_atom(:sl))
      assert [%Route{name: "CT1"}] == Enum.filter(@bus_routes, ModeView.bus_filter_atom(:ct))
    end

    test "Numeric bus route" do
      assert [%Route{name: "99"}] == Enum.filter(@bus_routes, ModeView.bus_filter_range(1, 100))
      assert [] == Enum.filter(@bus_routes, ModeView.bus_filter_range(200, 299))
    end
  end
end
