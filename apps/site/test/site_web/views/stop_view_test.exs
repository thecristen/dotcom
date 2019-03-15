defmodule SiteWeb.StopViewTest do
  use ExUnit.Case, async: false

  alias SiteWeb.PartialView.{HeaderTab, HeaderTabBadge}
  alias SiteWeb.StopView
  alias Stops.Stop
  alias Stops.Stop.ParkingLot
  alias Stops.Stop.ParkingLot.{Capacity, Manager, Payment}

  @stop_page_data %{
    routes: [
      %{
        group_name: :subway,
        routes: [
          %{
            custom_route?: false,
            description: :rapid_transit,
            direction_destinations: %{
              "0" => "Ashmont/Braintree",
              "1" => "Alewife"
            },
            direction_names: %{"0" => "South", "1" => "North"},
            id: "Red",
            long_name: "Red Line",
            name: "Red Line",
            type: 1
          }
        ]
      },
      %{
        group_name: :bus,
        routes: [
          %{
            custom_route?: false,
            description: :key_bus_route,
            direction_destinations: %{
              "0" => "Logan Airport",
              "1" => "South Station"
            },
            direction_names: %{"0" => "Outbound", "1" => "Inbound"},
            id: "741",
            long_name: "Logan Airport - South Station",
            name: "SL1",
            type: 3
          },
          %{
            custom_route?: false,
            description: :key_bus_route,
            direction_destinations: %{
              "0" => "Design Center",
              "1" => "South Station"
            },
            direction_names: %{"0" => "Outbound", "1" => "Inbound"},
            id: "742",
            long_name: "Design Center - South Station",
            name: "SL2",
            type: 3
          },
          %{
            custom_route?: false,
            description: :key_bus_route,
            direction_destinations: %{"0" => "Chelsea", "1" => "South Station"},
            direction_names: %{"0" => "Outbound", "1" => "Inbound"},
            id: "743",
            long_name: "Chelsea - South Station",
            name: "SL3",
            type: 3
          }
        ]
      },
      %{
        group_name: :commuter_rail,
        routes: [
          %{
            custom_route?: false,
            description: :commuter_rail,
            direction_destinations: %{"0" => "Fairmount", "1" => "South Station"},
            direction_names: %{"0" => "Outbound", "1" => "Inbound"},
            id: "CR-Fairmount",
            long_name: "Fairmount Line",
            name: "Fairmount Line",
            type: 2
          },
          %{
            custom_route?: false,
            description: :commuter_rail,
            direction_destinations: %{"0" => "Worcester", "1" => "South Station"},
            direction_names: %{"0" => "Outbound", "1" => "Inbound"},
            id: "CR-Worcester",
            long_name: "Framingham/Worcester Line",
            name: "Framingham/Worcester Line",
            type: 2
          },
          %{
            custom_route?: false,
            description: :commuter_rail,
            direction_destinations: %{
              "0" => "Forge Park/495",
              "1" => "South Station"
            },
            direction_names: %{"0" => "Outbound", "1" => "Inbound"},
            id: "CR-Franklin",
            long_name: "Franklin Line",
            name: "Franklin Line",
            type: 2
          },
          %{
            custom_route?: false,
            description: :commuter_rail,
            direction_destinations: %{"0" => "Greenbush", "1" => "South Station"},
            direction_names: %{"0" => "Outbound", "1" => "Inbound"},
            id: "CR-Greenbush",
            long_name: "Greenbush Line",
            name: "Greenbush Line",
            type: 2
          },
          %{
            custom_route?: false,
            description: :commuter_rail,
            direction_destinations: %{
              "0" => "Kingston or Plymouth",
              "1" => "South Station"
            },
            direction_names: %{"0" => "Outbound", "1" => "Inbound"},
            id: "CR-Kingston",
            long_name: "Kingston/Plymouth Line",
            name: "Kingston/Plymouth Line",
            type: 2
          },
          %{
            custom_route?: false,
            description: :commuter_rail,
            direction_destinations: %{
              "0" => "Middleborough/Lakeville",
              "1" => "South Station"
            },
            direction_names: %{"0" => "Outbound", "1" => "Inbound"},
            id: "CR-Middleborough",
            long_name: "Middleborough/Lakeville Line",
            name: "Middleborough/Lakeville Line",
            type: 2
          },
          %{
            custom_route?: false,
            description: :commuter_rail,
            direction_destinations: %{
              "0" => "Needham Heights",
              "1" => "South Station"
            },
            direction_names: %{"0" => "Outbound", "1" => "Inbound"},
            id: "CR-Needham",
            long_name: "Needham Line",
            name: "Needham Line",
            type: 2
          },
          %{
            custom_route?: false,
            description: :commuter_rail,
            direction_destinations: %{
              "0" => "Wickford Junction",
              "1" => "South Station"
            },
            direction_names: %{"0" => "Outbound", "1" => "Inbound"},
            id: "CR-Providence",
            long_name: "Providence/Stoughton Line",
            name: "Providence/Stoughton Line",
            type: 2
          }
        ]
      }
    ],
    stop: %Stop{
      accessibility: ["accessible", "escalator_both", "elevator", "fully_elevated_platform"],
      address: "700 Atlantic Ave, Boston, MA 02110",
      closed_stop_info: nil,
      has_charlie_card_vendor?: false,
      has_fare_machine?: true,
      id: "place-sstat",
      is_child?: false,
      latitude: 42.352271,
      longitude: -71.055242,
      name: "South Station",
      note: nil,
      parking_lots: [
        %ParkingLot{
          address: nil,
          capacity: %Capacity{
            accessible: 4,
            total: 210,
            type: "Garage"
          },
          latitude: 42.349838,
          longitude: -71.055963,
          manager: %Manager{
            contact: "ProPark",
            name: "ProPark",
            phone: "617-345-0202",
            url: "https://www.propark.com/propark-locator2/south-station-garage/"
          },
          name: "South Station Bus Terminal Garage",
          note: nil,
          payment: %Payment{
            daily_rate:
              "Hourly: 30 min: $5, 1 hr: $10, 1.5 hrs: $15, 2 hrs: $20, 2.5 hrs: $25, 3+ hrs: $30 | Daily Max: $30 | Early Bird (in by 8:30 AM, out by 6 PM): $26 | Nights/Weekends: $10",
            methods: ["Credit/Debit Card", "Cash"],
            mobile_app: nil,
            monthly_rate: "$150 regular, $445 overnight"
          },
          utilization: nil
        }
      ],
      station?: true
    },
    tabs: [
      %HeaderTab{
        badge: nil,
        class: "",
        href: "/stops-v2/place-sstat",
        id: "details",
        name: "Station Details"
      },
      %HeaderTab{
        badge: %HeaderTabBadge{
          aria_label: "1 alert",
          class: "m-alert-badge",
          content: "1"
        },
        class: "",
        href: "/stops/place-sstat?tab=alerts",
        id: "alerts",
        name: "Alerts"
      }
    ],
    zone_number: "1A"
  }

  test "render_react returns HTML" do
    assert {:safe, "<div" <> _} =
             StopView.render_react(%{
               stop_page_data: @stop_page_data,
               map_data: %{},
               map_id: "map"
             })
  end
end
