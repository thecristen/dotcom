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
        %{id: "Elevator", name: "Elevator"} => [Enum.at(alerts, 1)],
        %{id: "Escalator", name: "Escalator"} => [Enum.at(alerts, 0)],
        %{id: "Lift", name: "Lift"} => [Enum.at(alerts, 2)]
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
        %{id: "Elevator", name: "Elevator"} => alerts,
        %{id: "Escalator", name: "Escalator"} => [],
        %{id: "Lift", name: "Lift"} => [],
      }
    end

    test "ignores non Access Issue alerts" do
      assert group_access_alerts([%Alert{}]) == %{
        %{id: "Elevator", name: "Elevator"} => [],
        %{id: "Escalator", name: "Escalator"} => [],
        %{id: "Lift", name: "Lift"} => [],
      }
    end
  end
end
