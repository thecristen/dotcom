defmodule Alerts.StopTest do
  use ExUnit.Case, async: true
  alias Alerts.Alert
  alias Alerts.InformedEntity, as: IE
  alias Alerts.Stop

  @stop_id "stop_id"

  test "includes alerts that apply directly to the given stop" do
    alert = %Alert{informed_entity: [%IE{stop: @stop_id}]}
    wrong_alert = %Alert{informed_entity: [%IE{stop: "other stop"}]}

    assert [alert] == Stop.match([alert, wrong_alert], @stop_id)
  end

  test "does not include alerts that apply to a different route or route type" do
    alert = %Alert{informed_entity: [%IE{stop: @stop_id, route: "1", route_type: 1}]}
    wrong_route = %Alert{informed_entity: [%IE{stop: @stop_id, route: "2", route_type: 1}]}
    wrong_type = %Alert{informed_entity: [%IE{stop: @stop_id, route: "1", route_type: 2}]}

    assert [alert] == Stop.match(
      [alert, wrong_route, wrong_type],
      @stop_id,
      route: "1",
      route_type: 1)
  end

  test "does not include alerts that apply to the same route in a different direction" do
    alert = %Alert{informed_entity: [%IE{stop: @stop_id, route: "1", direction_id: 0}]}
    wrong_alert = %Alert{informed_entity: [%IE{stop: @stop_id, route: "1", direction_id: 1}]}

    assert [alert] == Stop.match(
      [alert, wrong_alert],
      @stop_id,
      route: "1",
      direction_id: 0)
  end

  test "does not include alerts that are not currently active" do
    now = Timex.now
    alert = %Alert{informed_entity: [%IE{stop: @stop_id}],
                   active_period: [{now, nil}]}
    wrong_alert = %Alert{alert | active_period: []}

    assert [alert] == Stop.match([alert, wrong_alert], @stop_id, time: now)
  end
end
