defmodule Site.ComponentsTest do
  use Site.ConnCase, async: true
  use Site.Components.Precompiler
  alias Site.Components.Buttons.ModeButton
  alias Site.Components.Buttons.ModeButtonList
  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "buttons > mode_button" do
    test "subway buttons render with T logo in a colored circle" do
      blue = mode_button(%ModeButton{
          route: %Routes.Route{id: "Blue", key_route?: true, name: "Blue Line", type: 1}
        }) |> safe_to_string
      assert blue =~ "icon-blue-line"
      assert blue =~ "icon-circle"
      assert blue =~ "t_logo-image"

      mattapan = mode_button(%ModeButton{
          route: %Routes.Route{id: "Mattapan", key_route?: true, name: "Mattapan Line", type: 1}
        }) |> safe_to_string
      assert mattapan =~ "icon-mattapan-line"
      assert mattapan =~ "icon-circle"
      assert mattapan =~ "t_logo-image"
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
                  active_period: current_active_period
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
      bus = svg_icon(%{icon: :bus})
      assert svg_icon(%{icon: %Routes.Route{type: 3}}) == bus
      assert svg_icon(%{icon: 3}) == bus
      red_line = svg_icon(%{icon: :red_line})
      assert svg_icon(%{icon: "Mattapan Line"}) == red_line
      assert svg_icon(%{icon: %Routes.Route{type: 1, id: "Red"}}) == red_line
      assert svg_icon(%{icon: "Escalator"}) == svg_icon(%{icon: :accessible})
    end

    test "icons render an svg with correct classes" do
      rendered = svg_icon(%{icon: :map}) |> safe_to_string
      assert rendered =~ "</svg>"
      assert rendered =~ "icon-map"
      assert rendered =~ "mbta-custom-icon"
    end

    test "icons do not render with a background circle" do
      rendered = svg_icon(%{icon: :subway}) |> safe_to_string
      assert rendered =~ "icon-subway"
      assert rendered =~ "mbta-custom-icon"
      refute rendered =~ "icon-circle"
    end
  end

  describe "icons > svg_icon_with_circle" do
    test "icons render an svg with a background circle and an icon positioned correctly" do
      rendered = svg_icon_with_circle(%{icon: :subway}) |> safe_to_string
      assert rendered =~ "</svg>"
      assert rendered =~ "mbta-custom-icon"
      assert rendered =~ "icon-circle"
      assert rendered =~ "icon-subway"
      assert rendered =~ "translate(12,9)"
    end
  end

  def current_active_period do
    [period_shift(minutes: -5), period_shift(minutes: 5)]
  end

  defp period_shift(period) do
    {Util.now |> Timex.shift(period), nil}
  end

end
