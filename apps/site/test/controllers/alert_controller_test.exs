defmodule Site.AlertControllerTest do
  use Site.ConnCase, async: true

  use Phoenix.Controller
  alias Alerts.Alert
  alias Site.Components.Icons.SvgIconWithCircle
  import Site.AlertController, only: [group_access_alerts: 1]

  test "renders commuter rail", %{conn: conn} do
    conn = get conn, alert_path(conn, :show, :commuter_rail)
    assert html_response(conn, 200) =~ "Commuter Rail"
  end

  describe "mode icons" do
    setup do
      {:ok, conn: build_conn, alerts: Enum.map([:bus, :subway, :commuter_rail, :ferry, :access], &create_alert/1)}
    end

    test "are shown on subway alerts", %{conn: conn, alerts: alerts} do
      response = render_alerts_page(conn, :subway, alerts)
      assert response =~ mode_icon_tag(:red_line)
    end
    test "are not shown on non-subway alerts", %{conn: conn, alerts: alerts} do
      for mode <- [:bus, :commuter_rail, :access] do
        response = render_alerts_page(conn, mode, alerts)
        assert response =~ "alert-show-title alert-show-title-#{mode}"
        refute response =~ mode_icon_tag(mode)
      end
    end

    defp render_alerts_page(conn, mode, alerts) do
      conn
      |> put_view(Site.AlertView)
      |> render("show.html", id: mode, route_alerts: alerts, breadcrumbs: ["Alerts"], date: Util.now())
      |> html_response(200)
    end

    defp mode_icon_tag(mode) do
      %SvgIconWithCircle{icon: mode}
      |> Site.AlertView.svg_icon_with_circle
      |> Phoenix.HTML.safe_to_string
      |> Kernel.<>(mode |> get_route |> Map.get(:name))
    end

    defp create_alert(mode) do
      mode
      |> get_route
      |> do_create_alert(mode)
    end

    defp get_route(:ferry), do: %Routes.Route{id: "Boat-F4", key_route?: false, name: "Charlestown Ferry", type: 4}
    defp get_route(:bus), do: %Routes.Route{id: "59", key_route?: false, name: "59", type: 3}
    defp get_route(mode) when mode in [:subway, :access, :red_line], do: %Routes.Route{id: "Red", key_route?: true,
                                                                                       name: "Red Line", type: 1}
    defp get_route(:commuter_rail), do: %Routes.Route{id: "CR-Fitchburg", key_route?: false,
                                                      name: "Fitchburg Line", type: 2}

    defp do_create_alert(route, mode) do
      {route, [%Alert{
        active_period: [{Util.now() |> Timex.shift(days: -2), nil}],
        informed_entity: [informed_entity(mode)],
        updated_at: Util.now() |> Timex.shift(days: -2),
        effect_name: effect_name(mode)
      }]}
    end

    defp informed_entity(mode) when mode in [:subway, :access] do
      %Alerts.InformedEntity{route: "Red", route_type: 1, direction_id: 1}
    end
    defp informed_entity(:commuter_rail) do
      %Alerts.InformedEntity{route: "CR-Fitchburg", route_type: 2, direction_id: 1}
    end
    defp informed_entity(:bus) do
      %Alerts.InformedEntity{route: "59", route_type: 3, direction_id: nil, stop: "81448", trip: nil}
    end
    defp informed_entity(:ferry) do
      %Alerts.InformedEntity{route: "Boat-F4", route_type: 4, direction_id: 1, stop: "Boat-Charlestown"}
    end

    defp effect_name(mode) when mode in [:subway, :ferry, :bus], do: "Delay"
    defp effect_name(:commuter_rail), do: "Track Change"
    defp effect_name(:access), do: "Access Issue"
  end

  describe "group_access_alerts/1" do
    test "given a list of alerts, groups the access alerts by type" do
      alerts = [
        "Escalator alert",
        "Elevator alert",
        "Lift alert"
      ]
      |> Enum.map(fn header ->
        %Alert{
          effect_name: "Access Issue",
          header: header}
      end)

      assert group_access_alerts(alerts) == %{
        %Routes.Route{id: "Elevator", name: "Elevator"} => [Enum.at(alerts, 1)],
        %Routes.Route{id: "Escalator", name: "Escalator"} => [Enum.at(alerts, 0)],
        %Routes.Route{id: "Lift", name: "Lift"} => [Enum.at(alerts, 2)]
      }
    end

    test "keeps alerts in order within a a type" do
      alerts = [
        "Elevator alert",
        "Elevator alert two",
      ]
      |> Enum.map(fn header ->
        %Alert{
          effect_name: "Access Issue",
          header: header}
      end)

      assert group_access_alerts(alerts) == %{
        %Routes.Route{id: "Elevator", name: "Elevator"} => alerts,
        %Routes.Route{id: "Escalator", name: "Escalator"} => [],
        %Routes.Route{id: "Lift", name: "Lift"} => [],
      }
    end

    test "ignores non Access Issue alerts" do
      assert group_access_alerts([%Alert{}]) == %{
        %Routes.Route{id: "Elevator", name: "Elevator"} => [],
        %Routes.Route{id: "Escalator", name: "Escalator"} => [],
        %Routes.Route{id: "Lift", name: "Lift"} => [],
      }
    end
  end
end
