defmodule Site.AlertControllerTest do
  use Site.ConnCase, async: true

  alias Alerts.Alert
  import Site.AlertController

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
        %{type: nil, id: "Elevator", name: "Elevator"} => [Enum.at(alerts, 1)],
        %{type: nil, id: "Escalator", name: "Escalator"} => [Enum.at(alerts, 0)],
        %{type: nil, id: "Lift", name: "Lift"} => [Enum.at(alerts, 2)]
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
        %{type: nil, id: "Elevator", name: "Elevator"} => alerts,
        %{type: nil, id: "Escalator", name: "Escalator"} => [],
        %{type: nil, id: "Lift", name: "Lift"} => [],
      }
    end

    test "ignores non Access Issue alerts" do
      assert group_access_alerts([%Alert{}]) == %{
        %{type: nil, id: "Elevator", name: "Elevator"} => [],
        %{type: nil, id: "Escalator", name: "Escalator"} => [],
        %{type: nil, id: "Lift", name: "Lift"} => [],
      }
    end
  end
end
