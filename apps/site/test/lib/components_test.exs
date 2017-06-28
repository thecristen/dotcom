defmodule Site.ComponentsTest do
  use Site.ConnCase, async: true
  use Site.Components.Precompiler
  alias Site.Components.Buttons.{ModeButtonList, ButtonGroup}
  alias Site.Components.Icons.SvgIcon
  alias Site.Components.Tabs.ModeTabList
  import Phoenix.HTML, only: [safe_to_string: 1]

  def check_mode_button_widths(routes, route_type, %{xs: xs, sm: sm, md: md, xxl: xxl}) do
    list = mode_button_list(%ModeButtonList{routes: routes, route_type: route_type}) |> safe_to_string
    [link_class] = list |> Floki.find(".button-container") |> List.first |> Floki.attribute("class")
    assert link_class =~ "col-xs-#{xs}"
    assert link_class =~ "col-sm-#{sm}"
    assert link_class =~ "col-md-#{md}"
    assert link_class =~ "col-xxl-#{xxl}"
  end

  describe "buttons > mode_button_list" do
    test "buttons render at the correct widths" do
      check_mode_button_widths([%Routes.Route{id: "Red", name: "Red Line", type: 1}], :subway,
        %{xs: 6, sm: 6, md: 3, xxl: 3})
      check_mode_button_widths([%Routes.Route{id: "CR-Fitchburg", name: "Fitchburg Line", type: 2}], :commuter_rail,
        %{xs: 6, sm: 6, md: 4, xxl: 3})
      check_mode_button_widths([%Routes.Route{id: "Boat-F4", name: "Hull Ferry", type: 4}], :ferry,
        %{xs: 12, sm: 4, md: 4, xxl: 4})
      check_mode_button_widths(Site.ModeView.get_route_group(:the_ride, []), :the_ride, %{xs: 12, sm: 6, md: 6, xxl: 3})
    end

    test "subway buttons render with T logo in a colored circle" do
      blue = mode_button_list(%ModeButtonList{
          routes: [%Routes.Route{id: "Blue", key_route?: true, name: "Blue Line", type: 1}],
          route_type: :subway,
      }) |> safe_to_string
      assert blue =~ "icon-blue-line"
      assert blue =~ "icon-circle"

      mattapan = mode_button_list(%ModeButtonList{
          routes: [%Routes.Route{id: "Mattapan", key_route?: true, name: "Mattapan Trolley", type: 1}],
          route_type: :subway
        }) |> safe_to_string
      assert mattapan =~ "icon-mattapan-trolley"
      assert mattapan =~ "icon-circle"
    end

    test "non-subway buttons do not render with color circles" do
      rendered = mode_button_list(%ModeButtonList{
          routes: [%Routes.Route{id: "701", key_route?: false, name: "CT1", type: 3}],
          route_type: :bus
        }) |> safe_to_string
      refute rendered =~ "fa-color-subway-blue"
    end

    test "routes with alerts get rendered with an alert" do
      rendered = mode_button_list(%ModeButtonList{
        routes: [%Routes.Route{id: "106", key_route?: false, name: "106", type: 3}],
        route_type: :bus,
        alerts: [%Alerts.Alert{
                  effect: :delay,
                  informed_entity: [%Alerts.InformedEntity{route: "106", route_type: 3}],
                  lifecycle: :new,
                  active_period: current_active_period()
        }]}) |> safe_to_string
      assert rendered =~ "icon-alert"
    end

    test "green line alerts are rendered with an alert icon" do
      rendered = mode_button_list(%ModeButtonList{
        routes: [%Routes.Route{id: "Green", key_route?: false, name: "Green", type: 1}],
        route_type: :bus,
        alerts: [%Alerts.Alert{
                  effect: :delay,
                  informed_entity: [%Alerts.InformedEntity{route: "Green", route_type: 1}],
                  lifecycle: :new,
                  active_period: current_active_period()
        }]})
      assert safe_to_string(rendered) =~ "icon-alert"
    end

    test "routes with notices but no alerts do not get rendered with an alert" do
      rendered = mode_button_list(%ModeButtonList{
        routes: [%Routes.Route{id: "CR-Haverhill", key_route?: false, name: "Haverhill Line", type: 2}],
        alerts: [%Alerts.Alert{
                  effect: :track_change,
                  informed_entity: [%Alerts.InformedEntity{route: "CR-Haverhill", route_type: 2}]
        }]}) |> safe_to_string
      refute rendered =~ "icon-alert"
    end

    test "includes a 'view all' link as last link if :truncated_list? is true and route_type is bus" do
      rendered = mode_button_list(%ModeButtonList{
        routes: [%Routes.Route{id: "1", name: "1", type: 3}],
        route_type: :bus,
        truncated_list?: true
      }) |> safe_to_string
      links = Floki.find(rendered, ".button-container")
      assert length(links) > 1
      assert links |> List.last |> Floki.text == "View all buses "
      assert links |> List.last |> Floki.find("a") |> Floki.attribute("href") == ["/schedules/bus"]
    end

    test "does not include a 'view all' link if route_type is bus and :truncated_list? != true" do
      rendered = mode_button_list(%ModeButtonList{
        routes: [%Routes.Route{id: "1", name: "1", type: 3}],
        route_type: :bus
        }) |> safe_to_string
      links = Floki.find(rendered, ".button-container")
      for link <- links do
        refute link |> Floki.text |> String.downcase =~ "view all buses"
        refute link |> Floki.find("a") |> Floki.attribute("href") == ["/schedules/bus"]
      end
    end

    test "does not include a 'view all' link for subway regardless of :truncated_list?" do
      rendered = mode_button_list(%ModeButtonList{
        routes: [%Routes.Route{id: "Red", name: "Red", type: 0}],
        route_type: :subway,
        truncated_list?: true
      }) |> safe_to_string
      refute Floki.find(rendered, ~s([href="/schedules/Red"])) == []
      assert Floki.find(rendered, ~s([href="/schedules/subway"])) == []
      refute rendered |> Floki.text |> String.downcase =~ "view all"
    end

    test "does not include a 'view all' link for commuter rail regardless of :truncated_list?" do
      rendered = mode_button_list(%ModeButtonList{
        routes: [%Routes.Route{id: "CR-Fitchburg", name: "Fitchburg Line", type: 2}],
        route_type: :commuter_rail,
        truncated_list?: true
      }) |> safe_to_string
      refute Floki.find(rendered, ~s([href="/schedules/CR-Fitchburg"])) == []
      assert Floki.find(rendered, ~s([href="/schedules/commuter_rail"])) == []
      refute rendered |> Floki.text |> String.downcase =~ "view all"
    end

    test "does not include a 'view all' link for ferry regardless of :truncated_list?" do
      rendered = mode_button_list(%ModeButtonList{
        routes: [%Routes.Route{id: "Boat-F4", name: "Hull Ferry", type: 4}],
        route_type: :ferry,
        truncated_list?: true
      }) |> safe_to_string
      refute Floki.find(rendered, ~s([href="/schedules/Boat-F4"])) == []
      assert Floki.find(rendered, ~s([href="/schedules/ferry"])) == []
      refute rendered |> Floki.text |> String.downcase =~ "view all"
    end

  end

  describe "buttons > button_group" do
    test "breakpoint_widths/1 returns a string of column classes" do
      args = %ButtonGroup{
        breakpoint_widths: %{
          xs: 10,
          md: 6
        }
      }
      result = ButtonGroup.breakpoint_widths(args)
      assert result =~ "col-xs-10"
      assert result =~ "col-sm-6" # default
      assert result =~ "col-md-6"
      assert result =~ "col-xxl-3" # default
    end

    test "button list renders with default widths when args.breakpoint_widths doesn't exist" do
      rendered = button_group(%ButtonGroup{
        links: [{"Link 1", "/link-1"}, {"Link 2", "/link-2"}]
      }) |> safe_to_string
      assert [{"div", [{"class", "button-group"}], links}] = Floki.find(rendered, ".button-group")
      for link <- links do
        assert Floki.attribute(link, "class") == ["button-container col-md-4 col-sm-6 col-xs-12 col-xxl-3"]
      end
    end
  end

  describe "icons > svg_icon" do
    test "icon can take multiple argument types and render the correct atom" do
      bus = svg_icon(%SvgIcon{icon: :bus})
      assert svg_icon(%SvgIcon{icon: %Routes.Route{type: 3}}) == bus
      assert svg_icon(%SvgIcon{icon: 3}) == bus
      red_line = svg_icon(%SvgIcon{icon: :red_line})
      mattapan_trolley = svg_icon(%SvgIcon{icon: :mattapan_trolley})
      assert svg_icon(%SvgIcon{icon: %Routes.Route{type: 0, id: "Mattapan"}}) == mattapan_trolley
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

    test "Title tooltip is shown if show_tooltip? is not specified" do
      rendered = svg_icon(%SvgIcon{icon: :subway}) |> safe_to_string
      [data_toggle] = Floki.find(rendered, "svg") |> List.first |> Floki.attribute("data-toggle")
      assert data_toggle == "tooltip"
    end

    test "Tooltip is not shown if show_tooltip? is false" do
      rendered = svg_icon(%SvgIcon{icon: :subway, show_tooltip?: false}) |> safe_to_string
      assert Floki.find(rendered, "svg") |> List.first |> Floki.attribute("data-toggle") == []
    end
  end

  describe "icons > svg_icon_with_circle" do
    test "icons render an svg with a background circle and an icon positioned correctly" do
      rendered = svg_icon_with_circle(%SvgIconWithCircle{icon: :subway}) |> safe_to_string
      assert rendered =~ "</svg>"
      assert rendered =~ "icon "
      assert rendered =~ "icon-circle"
      assert rendered =~ "icon-subway"
      assert rendered =~ "translate(4,4)"
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
      assert title(%Routes.Route{id: "Mattapan"}) == "Mattapan Trolley"
      assert title(%Routes.Route{id: "Green-B"}) == "Green Line"
      assert title(%Routes.Route{type: 4}) == "Ferry"
    end

    test "Title tooltip is shown if show_tooltip? is not specified" do
      rendered = svg_icon_with_circle(%SvgIconWithCircle{icon: :subway}) |> safe_to_string
      [data_toggle] = Floki.find(rendered, "svg") |> List.first |> Floki.attribute("data-toggle")
      assert data_toggle == "tooltip"
    end

    test "Tooltip is not shown if show_tooltip? is false" do
      rendered = svg_icon_with_circle(%SvgIconWithCircle{icon: :subway, show_tooltip?: false}) |> safe_to_string
      assert Floki.find(rendered, "svg") |> List.first |> Floki.attribute("data-toggle") == []
    end
  end

  describe "tabs > mode_tab_list" do
    @links [bus: "/bus", subway: "/subway", the_ride: "/the-ride", access: "/access"]

    def mode_tab_args do
      %ModeTabList{
        class: "navbar-toggleable-sm",
        links: @links,
        selected_mode: :bus,
      }
    end

    test "renders a list of tabs for with links for modes, including access and the ride" do
      rendered = mode_tab_args() |> mode_tab_list() |> safe_to_string()
      for link <- ["/bus#bus-tab", "/subway#subway-tab", "/the-ride#the-ride-tab", "/access#access-tab"] do
        assert rendered =~ ~s(href="#{link}")
      end
    end

    test "displays the selected tab as such" do
      rendered = mode_tab_args() |> mode_tab_list() |> safe_to_string()
      assert rendered =~ "tab-select-btn-selected"
    end

    test "renders icons for each mode" do
      rendered = mode_tab_args() |> mode_tab_list() |> safe_to_string()
      for mode <- ["bus", "subway", "the-ride", "access"] do
        assert rendered =~ "icon-#{mode}"
      end
    end

    test "mode_links/1" do
      expected = [{"bus", "Bus", "/bus"}, {"subway", "Subway", "/subway"}, {"the_ride", "The Ride", "/the-ride"}, {"access", "Access", "/access"}]
      assert mode_links(@links) == expected
    end

    test "build_icon_map/2" do
      icon_map = build_mode_icon_map(@links)
      assert safe_to_string(icon_map["Subway"]) =~ "icon-subway"
      assert safe_to_string(icon_map["Bus"]) =~ "icon-bus"
    end
  end

  describe "tabs > tab_selector" do
    @links [
      {"sched", "Schedules", "/schedules"},
      {"info", "Info", "/info"},
      {"etc", "Something Else", "/something-else"}
      ]

    def tab_args do
      %TabSelector{
        links: @links,
        selected: "info"
      }
    end

    test "renders a list of tabs" do
      rendered = tab_args() |> tab_selector() |> safe_to_string()

      for link <- ["/schedules#schedules-tab", "/info#info-tab", "/something-else#something-else-tab"] do
        assert rendered =~ ~s(href="#{link}")
      end
    end

    test "displays a tab as selected" do
      rendered = tab_args() |> tab_selector() |> safe_to_string()

      assert rendered =~ ~r/<a.*href=\"\/info#info-tab\"/
      assert rendered =~ ~r/class=.*tab-select-btn-selected/
    end

    test "optionally takes a CSS class" do
      rendered = tab_args() |> Map.put(:class, "test-class") |> tab_selector() |> safe_to_string()

      assert rendered =~ "test-class"
    end
  end

  describe "tabs > tab_selector" do
    @links [
      {"sched", "Schedules", "/schedules"},
      {"info", "Info", "/info"},
      {"etc", "Something Else", "/something-else"}
    ]

    def selector_args do
      %TabSelector{
        links: @links,
        selected: "info",
        icon_map: %{"Info" => "info-icon"},
      }
    end

    test "Icons are shown if given" do
      rendered = selector_args() |> tab_selector()  |> safe_to_string()
      option = rendered
      |> Floki.find(".tab-select-btn-selected")
      |> Enum.at(0)
      |> elem(2)
      |> List.first
      assert option =~ "info-icon"
    end

    test "Selected option is shown as such" do
      rendered = selector_args() |> tab_selector()  |> safe_to_string()
      option = rendered
      |> Floki.find(".tab-select-btn-selected")
      assert inspect(option) =~ "Info"
    end

    test "selected?/2" do
      assert selected?("info", "info")
      refute selected?("schedules", "info")
    end
  end

  def current_active_period do
    [period_shift(minutes: -5), period_shift(minutes: 5)]
  end

  defp period_shift(period) do
    {Util.now() |> Timex.shift(period), nil}
  end

end
