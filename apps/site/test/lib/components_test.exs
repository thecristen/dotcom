defmodule Site.ComponentsTest do
  use Site.ConnCase, async: true
  use Site.Components.Precompiler

  describe "buttons > mode_button" do
    test "subway buttons render with color circles" do
      rendered = mode_button(%Site.Components.Buttons.ModeButton{
          route: %Routes.Route{id: "Blue", key_route?: true, name: "Blue Line", type: 1}
        }) |> Phoenix.HTML.safe_to_string
      assert rendered =~ "fa-color-subway-blue"
    end

    test "non-subway buttons do not render with color circles" do
      rendered = mode_button(%Site.Components.Buttons.ModeButton{
          route: %Routes.Route{id: "701", key_route?: false, name: "CT1", type: 3}
        }) |> Phoenix.HTML.safe_to_string
      refute rendered =~ "fa-color-subway-blue"
    end

    test "buttons for routes with an alert get rendered with an alert icon" do
      rendered = mode_button(%Site.Components.Buttons.ModeButton{
        route: %Routes.Route{id: "106", key_route?: false, name: "106", type: 3},
        alert: %Alerts.Alert{
                  effect_name: "Delay",
                  informed_entity: [%Alerts.InformedEntity{route: "106", route_type: 3}],
                  lifecycle: "New",
                  severity: "Moderate"
        }}) |> Phoenix.HTML.safe_to_string
        assert rendered =~ "fa-exclamation-triangle"
    end

    test "buttons for routes with notices do not render with an alert icon" do
      rendered = mode_button(%Site.Components.Buttons.ModeButton{
        route: %Routes.Route{id: "106", key_route?: false, name: "106", type: 3}
        }) |> Phoenix.HTML.safe_to_string
      refute rendered =~ "fa-exclamation-triangle"
    end
  end

  describe "buttons > mode_button_list" do
    test "routes with alerts get rendered with an alert" do
      rendered = mode_button_list(%Site.Components.Buttons.ModeButtonList{
        routes: [%Routes.Route{id: "106", key_route?: false, name: "106", type: 3}],
        alerts: [%Alerts.Alert{
                  effect_name: "Delay",
                  informed_entity: [%Alerts.InformedEntity{route: "106", route_type: 3}],
                  lifecycle: "New",
                  severity: "Moderate",
                  active_period: current_active_period
        }]}) |> Phoenix.HTML.safe_to_string
      assert rendered =~ "fa-exclamation-triangle"
    end
    
    test "routes with notices but no alerts do not get rendered with an alert" do
      rendered = mode_button_list(%Site.Components.Buttons.ModeButtonList{
        routes: [%Routes.Route{id: "CR-Haverhill", key_route?: false, name: "Haverhill Line", type: 2}],
        alerts: [%Alerts.Alert{
                  effect_name: "Track Change",
                  informed_entity: [%Alerts.InformedEntity{route: "CR-Haverhill", route_type: 2}]
        }]}) |> Phoenix.HTML.safe_to_string
      refute rendered =~ "fa-exclamation-triangle"
    end
  end

  def current_active_period do
    [period_shift(minutes: -5), period_shift(minutes: 5)]
  end

  defp period_shift(period) do
    {Util.now |> Timex.shift(period), nil}
  end

end
