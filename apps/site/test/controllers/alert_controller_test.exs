defmodule Site.AlertControllerTest do
  use Site.ConnCase, async: true

  alias Alerts.Alert
  import Site.AlertController


  test "renders commuter rail", %{conn: conn} do
    conn = get conn, alert_path(conn, :show, :commuter_rail)
    assert html_response(conn, 200) =~ "Commuter Rail"
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
