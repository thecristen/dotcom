defmodule Site.ControllerHelpersTest do
  use Site.ConnCase, async: true
  import Site.ControllerHelpers

  describe "filter_modes/2" do
    test "filters the key routes of all modes that are passed" do
      routes = [
        {:subway, [%Routes.Route{direction_names: %{0 => "Southbound", 1 => "Northbound"},
         id: "Red", key_route?: true, name: "Red Line", type: 1},
        %Routes.Route{direction_names: %{0 => "Outbound", 1 => "Inbound"},
         id: "Mattapan", key_route?: false, name: "Mattapan Trolley", type: 0}]},
        {:bus, [%Routes.Route{direction_names: %{0 => "Outbound", 1 => "Inbound"}, id: "22",
         key_route?: true, name: "22", type: 3},
        %Routes.Route{direction_names: %{0 => "Outbound", 1 => "Inbound"}, id: "23",
         key_route?: true, name: "23", type: 3},
         %Routes.Route{direction_names: %{0 => "Outbound", 1 => "Inbound"}, id: "40",
             key_route?: false, name: "40", type: 3}]
      }]

      assert filter_routes(routes, [:subway, :bus]) ==
        [{:subway, [%Routes.Route{direction_names: %{0 => "Southbound", 1 => "Northbound"},
         id: "Red", key_route?: true, name: "Red Line", type: 1}]},
        {:bus, [%Routes.Route{direction_names: %{0 => "Outbound", 1 => "Inbound"}, id: "22",
         key_route?: true, name: "22", type: 3},
        %Routes.Route{direction_names: %{0 => "Outbound", 1 => "Inbound"}, id: "23",
         key_route?: true, name: "23", type: 3}]}]
    end
  end

  describe "get_grouped_route_ids/1" do
    @grouped_routes [
      subway: [
        %Routes.Route{id: "sub1", type: 0},
        %Routes.Route{id: "sub2", type: 1}
      ],
      bus: [
        %Routes.Route{id: "bus1", type: 3}
      ],
      commuter_rail: [
        %Routes.Route{id: "comm1", type: 2},
        %Routes.Route{id: "comm2", type: 2}
      ]
    ]

    test "returns list of ids from the given grouped routes" do
      assert get_grouped_route_ids(@grouped_routes) == ["sub1", "sub2", "bus1", "comm1", "comm2"]
    end
  end

  describe "assign_all_alerts/2" do
    @worcester %Alerts.InformedEntity{route: "CR-Worcester", route_type: 2}
    @worcester_inbound %Alerts.InformedEntity{route: "CR-Worcester", direction_id: 1}
    @commuter_rail %Alerts.InformedEntity{route_type: 2}
    @bus %Alerts.InformedEntity{route_type: 3}

    @worcester_alert  %Alerts.Alert{id: "worcester", informed_entity: [@worcester]}
    @worcester_inbound_alert %Alerts.Alert{id: "worcester-inbound", informed_entity: [@worcester_inbound]}
    @commuter_rail_alert %Alerts.Alert{id: "commuter-rail", informed_entity: [@commuter_rail]}
    @bus_alert %Alerts.Alert{id: "bus", informed_entity: [@bus]}

    setup do
      Alerts.Cache.Store.update([@worcester_alert,
                                 @worcester_inbound_alert,
                                 @commuter_rail_alert,
                                 @bus_alert
                               ], nil)

    end

    test "assigns all alerts for the route id, type, and direction", %{conn: conn} do
      route = %Routes.Route{id: "CR-Worcester", type: 2}
      alerts =
        conn
        |> assign(:date_time, Timex.now())
        |> assign(:route, route)
        |> assign(:direction_id, 1)
        |> assign_all_alerts([])
        |> (fn conn -> conn.assigns.all_alerts end).()

      expected = [@commuter_rail_alert, @worcester_alert, @worcester_inbound_alert]
      assert alerts == expected
    end

    test "does not assign an alert in the opposite direction", %{conn: conn} do
      route = %Routes.Route{id: "CR-Worcester", type: 2}
      alerts =
        conn
        |> assign(:date_time, Timex.now())
        |> assign(:route, route)
        |> assign(:direction_id, 0)
        |> assign_all_alerts([])
        |> (fn conn -> conn.assigns.all_alerts end).()

      expected = [@commuter_rail_alert, @worcester_alert]
      assert alerts == expected
    end

    test "assigns alerts for both directions if the direction_id is nil", %{conn: conn} do
      route = %Routes.Route{id: "CR-Worcester", type: 2}
      alerts =
        conn
        |> assign(:date_time, Timex.now())
        |> assign(:route, route)
        |> assign(:direction_id, nil)
        |> assign_all_alerts([])
        |> (fn conn -> conn.assigns.all_alerts end).()

      expected = [@commuter_rail_alert, @worcester_alert, @worcester_inbound_alert]
      assert alerts == expected
    end

    test "assigns alerts for both directions if the direction_id is not assigned", %{conn: conn} do
      route = %Routes.Route{id: "CR-Worcester", type: 2}
      alerts =
        conn
        |> assign(:date_time, Timex.now())
        |> assign(:route, route)
        |> assign_all_alerts([])
        |> (fn conn -> conn.assigns.all_alerts end).()

      expected = [@commuter_rail_alert, @worcester_alert, @worcester_inbound_alert]
      assert alerts == expected
    end

    test "assigns alerts when any of the matching informed entities have a nil direction,
          even if others have conflicting direction ids (which shouldn't happen)", %{conn: conn} do
      worcester_ambiguous_alert = %Alerts.Alert{@worcester_inbound_alert |
        id: "worcester-ambiguous",
        informed_entity: [@worcester_inbound, @worcester]
      }
      Alerts.Cache.Store.update([@worcester_alert,
                                 @worcester_inbound_alert,
                                 worcester_ambiguous_alert,
                                 @commuter_rail_alert,
                                 @bus_alert
                               ], nil)

      route = %Routes.Route{id: "CR-Worcester", type: 2}
      alerts =
        conn
        |> assign(:date_time, Timex.now())
        |> assign(:route, route)
        |> assign(:direction_id, 0)
        |> assign_all_alerts([])
        |> (fn conn -> conn.assigns.all_alerts end).()

      expected = [@commuter_rail_alert, @worcester_alert, worcester_ambiguous_alert]
      assert alerts == expected
    end
  end
end
