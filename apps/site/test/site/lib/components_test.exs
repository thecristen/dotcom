defmodule Site.ComponentsTest do
  use SiteWeb.ConnCase, async: true
  use Site.Components.Precompiler
  alias Site.Components.Buttons.{ModeButtonList, ButtonGroup}
  alias Site.Components.Icons.SvgIcon
  alias Site.Components.Tabs.ModeTabList
  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "buttons > mode_button_list" do
    test "subway buttons render with T logo in a colored circle" do
      blue =
        %ModeButtonList{
          routes: [%Routes.Route{id: "Blue", key_route?: true, name: "Blue Line", type: 1}],
          route_type: :subway,
        }
        |> mode_button_list()
        |> safe_to_string()

      assert blue =~ "icon-blue-line"

      mattapan =
        %ModeButtonList{
          routes: [%Routes.Route{id: "Mattapan", key_route?: true, name: "Mattapan Trolley", type: 1}],
          route_type: :subway
        }
        |> mode_button_list()
        |> safe_to_string()

      assert mattapan =~ "icon-mattapan-line"
    end

    test "non-subway buttons do not render with color circles" do
      rendered =
        %ModeButtonList{
          routes: [%Routes.Route{id: "701", key_route?: false, name: "CT1", type: 3}],
          route_type: :bus
        }
        |> mode_button_list()
        |> safe_to_string()

      refute rendered =~ "fa-color-subway-blue"
    end

    test "routes with alerts get rendered with an alert" do
      rendered = mode_button_list(%ModeButtonList{
        routes: [%Routes.Route{id: "106", key_route?: false, name: "106", type: 3}],
        route_type: :bus,
        alerts: [Alerts.Alert.new(
                  effect: :delay,
                  informed_entity: [%Alerts.InformedEntity{route: "106", route_type: 3}],
                  lifecycle: :new,
                  active_period: current_active_period()
        )]})
      assert safe_to_string(rendered) =~ "icon-alert"
    end

    test "routes with a slash and an alert get properly no-wrap-ed" do
      rendered = %ModeButtonList{
        routes: [%Routes.Route{id: "CR-Providence", name: "Providence/Stoughton", type: 2}],
        route_type: :commuter_rail,
        alerts: [Alerts.Alert.new(
                  effect: :delay,
                  informed_entity: [%Alerts.InformedEntity{route: "CR-Providence", route_type: 2}],
                  lifecycle: :new,
                  active_period: current_active_period()
                  )]}
      |> mode_button_list
      |> safe_to_string
      assert rendered =~ "wbr"
      assert rendered =~ "nowrap"
    end

    test "green line alerts are rendered with an alert icon" do
      rendered = mode_button_list(%ModeButtonList{
        routes: [%Routes.Route{id: "Green", key_route?: false, name: "Green", type: 1}],
        route_type: :bus,
        alerts: [Alerts.Alert.new(
                  effect: :delay,
                  informed_entity: [%Alerts.InformedEntity{route: "Green", route_type: 1}],
                  lifecycle: :new,
                  active_period: current_active_period()
        )]})
      assert safe_to_string(rendered) =~ "icon-alert"
    end

    test "routes with notices but no alerts do not get rendered with an alert" do
      rendered = mode_button_list(%ModeButtonList{
        routes: [%Routes.Route{id: "CR-Haverhill", key_route?: false, name: "Haverhill Line", type: 2}],
        alerts: [Alerts.Alert.new(
                  effect: :track_change,
                  informed_entity: [%Alerts.InformedEntity{route: "CR-Haverhill", route_type: 2}]
        )]})
      refute safe_to_string(rendered) =~ "icon-alert"
    end

    test "includes a 'view all' link as last link if :truncated_list? is true and route_type is bus" do
      rendered = mode_button_list(%ModeButtonList{
        routes: [%Routes.Route{id: "1", name: "1", type: 3}],
        route_type: :bus,
        truncated_list?: true
      })
      links = rendered |> safe_to_string() |> Floki.find(".button-container")
      assert length(links) > 1
      assert links |> List.last |> Floki.text == "View all buses "
      assert links |> List.last |> Floki.find("a") |> Floki.attribute("href") == ["/schedules/bus"]
    end

    test "does not include a 'view all' link if route_type is bus and :truncated_list? != true" do
      rendered = mode_button_list(%ModeButtonList{
        routes: [%Routes.Route{id: "1", name: "1", type: 3}],
        route_type: :bus
        })
      links = rendered |> safe_to_string() |> Floki.find(".button-container")
      for link <- links do
        refute link |> Floki.text |> String.downcase =~ "view all buses"
        refute link |> Floki.find("a") |> Floki.attribute("href") == ["/schedules/bus"]
      end
    end

    test "does not include a 'view all' link for subway regardless of :truncated_list?" do
      rendered = %ModeButtonList{
        routes: [%Routes.Route{id: "Red", name: "Red", type: 0}],
        route_type: :subway,
        truncated_list?: true
      }
      |> mode_button_list()
      |> safe_to_string()
      refute Floki.find(rendered, ~s([href="/schedules/Red"])) == []
      assert Floki.find(rendered, ~s([href="/schedules/subway"])) == []
      refute rendered |> Floki.text |> String.downcase =~ "view all"
    end

    test "does not include a 'view all' link for commuter rail regardless of :truncated_list?" do
      rendered =
        %ModeButtonList{
          routes: [%Routes.Route{id: "CR-Fitchburg", name: "Fitchburg Line", type: 2}],
          route_type: :commuter_rail,
          truncated_list?: true
        }
        |> mode_button_list()
        |> safe_to_string()
      refute Floki.find(rendered, ~s([href="/schedules/CR-Fitchburg"])) == []
      assert Floki.find(rendered, ~s([href="/schedules/commuter-rail"])) == []
      refute rendered |> Floki.text |> String.downcase =~ "view all"
    end

    test "does not include a 'view all' link for ferry regardless of :truncated_list?" do
      rendered =
        %ModeButtonList{
          routes: [%Routes.Route{id: "Boat-F4", name: "Hull Ferry", type: 4}],
          route_type: :ferry,
          truncated_list?: true
        }
        |> mode_button_list()
        |> safe_to_string()

      refute Floki.find(rendered, ~s([href="/schedules/Boat-F4"])) == []
      assert Floki.find(rendered, ~s([href="/schedules/ferry"])) == []
      refute rendered |> Floki.text |> String.downcase =~ "view all"
    end

  end

  describe "buttons > button_group" do
    test "button list renders links in button containers" do
      rendered =
        %ButtonGroup{links: [{"Link 1", "/link-1"}, {"Link 2", "/link-2"}]}
        |> button_group()
        |> safe_to_string()
      assert [{"div", [{"class", "button-group"}], links}] = Floki.find(rendered, ".button-group")
      for link <- links do
        assert Floki.attribute(link, "class") == ["button-container"]
      end
    end
  end

  describe "icons > svg_icon" do
    test "raises an error if icon not found" do
      assert_raise RuntimeError, "fail icon not found", fn -> svg_icon(%SvgIcon{icon: :fail}) end
    end

    test "icon can take multiple argument types and render the correct atom" do
      bus = svg_icon(%SvgIcon{icon: :bus})
      assert svg_icon(%SvgIcon{icon: %Routes.Route{type: 3}}) == bus
      assert svg_icon(%SvgIcon{icon: 3}) == bus
      red_line = svg_icon(%SvgIcon{icon: :red_line})
      mattapan_line = svg_icon(%SvgIcon{icon: :mattapan_line})
      assert svg_icon(%SvgIcon{icon: %Routes.Route{type: 0, id: "Mattapan"}}) == mattapan_line
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
      rendered = %SvgIcon{icon: :subway} |> svg_icon() |> safe_to_string()
      [data_toggle] = rendered |> Floki.find("svg") |> List.first() |> Floki.attribute("data-toggle")
      assert data_toggle == "tooltip"
    end

    test "Tooltip is not shown if show_tooltip? is false" do
      rendered = %SvgIcon{icon: :subway, show_tooltip?: false} |> svg_icon() |> safe_to_string()
      assert rendered |> Floki.find("svg") |> List.first() |> Floki.attribute("data-toggle") == []
    end
  end

  describe "tabs > mode_tab_list" do
    @links [{"commuter-rail", "/commuter-rail"}, {"bus", "/bus"}, {"subway", "/subway"}, {"the_ride", "/the-ride"}, {"access", "/access"}]

    def mode_tab_args do
      %ModeTabList{
        class: "navbar-toggleable-sm",
        links: @links,
        selected_mode: :bus,
      }
    end

    test "renders a list of tabs for with links for modes, including access and the ride" do
      rendered = mode_tab_args() |> mode_tab_list() |> safe_to_string()
      for link <- ["/commuter-rail#commuter-rail-tab", "/bus#bus-tab", "/subway#subway-tab", "/the-ride#the-ride-tab", "/access#access-tab"] do
        assert rendered =~ ~s(href="#{link}")
      end
    end

    test "displays the selected tab as such" do
      rendered = mode_tab_args() |> mode_tab_list() |> safe_to_string()
      assert rendered =~ "tab-select-btn-selected"
    end

    test "renders icons for each mode" do
      rendered = mode_tab_args() |> mode_tab_list() |> safe_to_string()
      for mode <- ["bus", "subway"] do
        assert rendered =~ "icon-mode-#{mode}"
      end
      for icon <- ["the-ride", "accessible"] do
        assert rendered =~ "icon-#{icon}"
      end
    end

    test "mode_links/1" do
      expected = [{"commuter_rail", "Commuter Rail", "/commuter-rail"}, {"bus", "Bus", "/bus"}, {"subway", "Subway", "/subway"}, {"the_ride", "The Ride", "/the-ride"}, {"access", "Access", "/access"}]
      assert mode_links(@links) == expected
    end

    test "build_icon_map/2" do
      icon_map = build_mode_icon_map(@links)
      assert safe_to_string(icon_map["Subway"]) =~ "icon-mode-subway"
      assert safe_to_string(icon_map["Bus"]) =~ "icon-mode-bus"
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
        selected: "info",
        icon_map: %{"Info" => "info-icon"},
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

    test "Icons are shown if given" do
      rendered = tab_args() |> tab_selector()  |> safe_to_string()
      option = rendered
      |> Floki.find(".tab-select-btn-selected")
      |> Enum.at(0)
      |> elem(2)
      |> List.first
      assert option =~ "info-icon"
    end

    test "Selected option is shown as such" do
      rendered = tab_args() |> tab_selector()  |> safe_to_string()
      option = rendered
      |> Floki.find(".tab-select-btn-selected")
      assert inspect(option) =~ "Info"
    end

    test "selected?/2" do
      assert selected?("info", "info")
      refute selected?("schedules", "info")
    end
  end

  describe "get_path/1" do
    test "can take a %Route{}" do
      assert %Routes.Route{id: "Red"}
              |> get_path()
              |> safe_to_string() =~ "<path"
    end
  end

  def current_active_period do
    [period_shift(minutes: -5), period_shift(minutes: 5)]
  end

  defp period_shift(period) do
    {Util.now() |> Timex.shift(period), nil}
  end

end
