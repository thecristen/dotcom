defmodule Site.ComponentsTest do
  use Site.ConnCase, async: true
  use Site.Components.Precompiler
  alias Site.Components.Buttons.ModeButton
  alias Site.Components.Buttons.ModeButtonList
  alias Site.Components.Icons.SvgIcon
  alias Site.Components.Tabs.ModeTabList
  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "buttons > mode_button" do
    test "subway buttons render with T logo in a colored circle" do
      blue = mode_button(%ModeButton{
          route: %Routes.Route{id: "Blue", key_route?: true, name: "Blue Line", type: 1}
        }) |> safe_to_string
      assert blue =~ "icon-blue-line"
      assert blue =~ "icon-circle"

      mattapan = mode_button(%ModeButton{
          route: %Routes.Route{id: "Mattapan", key_route?: true, name: "Mattapan Line", type: 1}
        }) |> safe_to_string
      assert mattapan =~ "icon-mattapan-line"
      assert mattapan =~ "icon-circle"
    end

    test "non-subway buttons do not render with color circles" do
      rendered = mode_button(%ModeButton{
          route: %Routes.Route{id: "701", key_route?: false, name: "CT1", type: 3}
        }) |> safe_to_string
      refute rendered =~ "fa-color-subway-blue"
    end

    test "buttons for routes with an alert get rendered with an alert icon" do
      rendered = mode_button(%ModeButton{
        route: %Routes.Route{id: "106", key_route?: false, name: "106", type: 3},
        alert: %Alerts.Alert{
                  effect_name: "Delay",
                  informed_entity: [%Alerts.InformedEntity{route: "106", route_type: 3}],
                  lifecycle: "New",
                  severity: "Moderate"
        }}) |> safe_to_string
        assert rendered =~ "icon-alert"
        refute rendered =~ "icon-circle"
    end

    test "buttons for routes with notices do not render with an alert icon" do
      rendered = mode_button(%ModeButton{
        route: %Routes.Route{id: "106", key_route?: false, name: "106", type: 3}
        }) |> safe_to_string
      refute rendered =~ "icon-alert"
    end
  end

  describe "buttons > mode_button_list" do
    test "routes with alerts get rendered with an alert" do
      rendered = mode_button_list(%ModeButtonList{
        routes: [%Routes.Route{id: "106", key_route?: false, name: "106", type: 3}],
        alerts: [%Alerts.Alert{
                  effect_name: "Delay",
                  informed_entity: [%Alerts.InformedEntity{route: "106", route_type: 3}],
                  lifecycle: "New",
                  severity: "Moderate",
                  active_period: current_active_period()
        }]}) |> safe_to_string
      assert rendered =~ "icon-alert"
      refute rendered =~ "icon-circle"
    end

    test "routes with notices but no alerts do not get rendered with an alert" do
      rendered = mode_button_list(%ModeButtonList{
        routes: [%Routes.Route{id: "CR-Haverhill", key_route?: false, name: "Haverhill Line", type: 2}],
        alerts: [%Alerts.Alert{
                  effect_name: "Track Change",
                  informed_entity: [%Alerts.InformedEntity{route: "CR-Haverhill", route_type: 2}]
        }]}) |> safe_to_string
      refute rendered =~ "icon-alert"
    end
  end

  describe "icons > svg_icon" do
    test "icon can take multiple argument types and render the correct atom" do
      bus = svg_icon(%SvgIcon{icon: :bus})
      assert svg_icon(%SvgIcon{icon: %Routes.Route{type: 3}}) == bus
      assert svg_icon(%SvgIcon{icon: 3}) == bus
      red_line = svg_icon(%SvgIcon{icon: :red_line})
      assert svg_icon(%SvgIcon{icon: %Routes.Route{type: 0, id: "Mattapan"}}) == red_line
      assert svg_icon(%SvgIcon{icon: %Routes.Route{type: 1, id: "Red"}}) == red_line
      assert svg_icon(%SvgIcon{icon: "Escalator"}) == svg_icon(%SvgIcon{icon: :access})
    end

    test "icons render an svg with correct classes" do
      rendered = %SvgIcon{icon: :map} |> svg_icon |> safe_to_string
      assert rendered =~ "</svg>"
      assert rendered =~ "icon-map"
      assert rendered =~ "icon "
    end

    test "icons do not render with a background circle" do
      rendered = %SvgIcon{icon: :subway} |> svg_icon |> safe_to_string
      assert rendered =~ "icon-subway"
      assert rendered =~ "icon "
      refute rendered =~ "icon-circle"
    end

    test "alert icons have an accessible title" do
      rendered = %SvgIcon{icon: :alert} |> svg_icon |> safe_to_string
      assert rendered =~ "Service alert or delay"
    end
  end

  describe "icons > svg_icon_with_circle" do
    test "icons render an svg with a background circle and an icon positioned correctly" do
      rendered = svg_icon_with_circle(%SvgIconWithCircle{icon: :subway}) |> safe_to_string
      assert rendered =~ "</svg>"
      assert rendered =~ "icon "
      assert rendered =~ "icon-circle"
      assert rendered =~ "icon-subway"
      assert rendered =~ "translate(12,9)"
      assert rendered =~ "title=\"Subway\""
    end

    test "optionally accepts a class argument" do
      rendered = svg_icon_with_circle(%SvgIconWithCircle{icon: :subway, class: "test-class"}) |> safe_to_string
      assert rendered =~ ~r(class.*test-class)
    end

    test "title/1" do
      assert title(:blue_line) == "Blue Line"
      assert title(%Routes.Route{id: "Orange"}) == "Orange Line"
      assert title(%Routes.Route{id: "Red"}) == "Red Line"
      assert title(%Routes.Route{id: "Blue"}) == "Blue Line"
      assert title(%Routes.Route{id: "Mattapan"}) == "Mattapan Line"
      assert title(%Routes.Route{id: "Green-B"}) == "Green Line"
      assert title(%Routes.Route{type: 4}) == "Ferry"
    end
  end

  describe "tabs > mode_tab_list" do
    def mode_tab_args do
      %ModeTabList{
        class: "navbar-toggleable-sm",
        links: [{:bus, "/bus"}, {:subway, "/subway"}, {:the_ride, "/the-ride"}, {:access, "/access"}],
        selected_mode: :bus,
      }
    end

    test "renders a list of tabs for with links for modes, including access and the ride" do
      rendered = mode_tab_args() |> mode_tab_list() |> safe_to_string()
      for link <- ["/bus", "/subway", "/the-ride", "/access"] do
        assert rendered =~ ~s(href="#{link}")
      end
    end

    test "displays the selected tab as such" do
      rendered = mode_tab_args() |> mode_tab_list() |> safe_to_string()
      assert rendered =~ "alert-show-btn-bus show-btn-selected"
      assert rendered =~ "btn-selected-bottom-bus"
    end

    test "renders icons for each mode" do
      rendered = mode_tab_args() |> mode_tab_list() |> safe_to_string()
      for mode <- ["bus", "subway", "the-ride", "access"] do
        assert rendered =~ "icon-#{mode}"
      end
    end

    test "btn_class/1" do
      assert btn_class("xs") == "hidden-sm-up"
      assert btn_class("sm") == "hidden-md-up"
      assert btn_class(nil) == ""
    end

    test "nav_class/1" do
      assert nav_class("xs") == "collapse navbar-toggleable-xs"
      assert nav_class("sm") == "collapse navbar-toggleable-sm"
      assert nav_class(nil) == ""
    end
  end

  describe "tabs > tab_list" do
    def tab_args do
      %TabList{
        links: [
          {"Schedules", "/schedules", false},
          {"Info", "/info", true},
          {"Something Else", "/something-else", false}
        ]
      }
    end

    test "renders a list of tabs" do
      rendered = tab_args() |> tab_list() |> safe_to_string()

      for link <- ["/schedules", "/info", "/something-else"] do
        assert rendered =~ ~s(href="#{link}")
      end
    end

    test "displays a tab as selected" do
      rendered = tab_args() |> tab_list() |> safe_to_string()

      assert rendered =~ ~s(<a class="tab-list-tab tab-list-selected" href="/info">Info</a>)
    end

    test "optionally takes a CSS class" do
      rendered = tab_args() |> Map.put(:class, "test-class") |> tab_list() |> safe_to_string()

      assert rendered =~ ~s(<div class="tab-list-group show-btn-group test-class">)
    end

    test "tab_class/1" do
      assert tab_class(true) == "tab-list-tab tab-list-selected"
      assert tab_class(false) == "tab-list-tab"
    end
  end

  def current_active_period do
    [period_shift(minutes: -5), period_shift(minutes: 5)]
  end

  defp period_shift(period) do
    {Util.now() |> Timex.shift(period), nil}
  end

end
