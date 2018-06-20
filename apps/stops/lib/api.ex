defmodule Stops.Api do
  @moduledoc """
  Wrapper around the remote stop information service.
  """
  alias Stops.Stop

  @accessible_facilities ~w(elevator escalator ramp portable_boarding_lift
                            tty_phone elevated_subplatform fully_elevated_platform
                            escalator_up escalator_down escalator_both)a

  @doc """
  Returns a Stop by its GTFS ID.

  If a stop is found, we return `{:ok, %Stop{}}`. If no stop exists with that
  ID, we return `{:ok, nil}`. If there's an error fetching data, we return
  that as an `{:error, any}` tuple.
  """
  @spec by_gtfs_id(String.t) :: {:ok, Stop.t | nil} | {:error, any}
  def by_gtfs_id(gtfs_id) do
    gtfs_id
    |> V3Api.Stops.by_gtfs_id
    |> extract_v3_response
    |> parse_v3_response
  end

  @spec by_route({Routes.Route.id_t, 0 | 1, Keyword.t}) :: [Stop.t]
  def by_route({"Red" = route_id, direction_id, opts}) do
    route_id
    |> get_stops(direction_id, opts)
  end
  def by_route({route_id, direction_id, opts}) do
    get_stops(route_id, direction_id, opts)
  end

  @spec get_stops(Routes.Route.id_t, 0 | 1, Keyword.t) :: [Stops.Stop.t]
  defp get_stops(route_id, direction_id, opts) do
    params = [
      route: route_id,
      include: "parent_station,facilities",
      direction_id: direction_id,
      "fields[facility]": "name,type,properties",
      "fields[stop]": "address,name,latitude,longitude,address,wheelchair_boarding,location_type"
    ]

    params
    |> Keyword.merge(opts)
    |> V3Api.Stops.all
    |> parse_v3_multiple
  end

  @spec by_route_type({0..4, Keyword.t}) :: [Stop.t]
  def by_route_type({route_type, opts}) do
    [
      route_type: route_type,
      include: "parent_station,facilities",
      "fields[facility]": "name,type,properties",
      "fields[stop]": "address,name,latitude,longitude,address,wheelchair_boarding,location_type"
    ]
    |> Keyword.merge(opts)
    |> V3Api.Stops.all
    |> parse_v3_multiple
  end

  @spec parse_v3_multiple(JsonApi.t | {:error, any}) :: [Stops.Stop.t] | {:error, any}
  defp parse_v3_multiple({:error, _} = error) do
    error
  end
  defp parse_v3_multiple(api) do
    api.data
    |> Enum.map(&parse_v3_response/1)
    |> Enum.map(fn {:ok, stop} -> stop end)
  end

  @spec v3_id(JsonApi.Item.t) :: Stop.id_t
  defp v3_id(%JsonApi.Item{relationships: %{"parent_station" => [%JsonApi.Item{id: parent_id}]}}) do
    parent_id
  end
  defp v3_id(item) do
    item.id
  end

  @spec v3_name(JsonApi.Item.t) :: String.t
  defp v3_name(%JsonApi.Item{relationships: %{"parent_station" => [%JsonApi.Item{attributes: %{"name" => parent_name}}]}}) do
    parent_name
  end
  defp v3_name(item) do
    item.attributes["name"]
  end

  @spec extract_v3_response(JsonApi.t) :: {:ok, JsonApi.Item.t} | {:error, any}
  defp extract_v3_response(%JsonApi{data: [item | _]}) do
    {:ok, item}
  end
  defp extract_v3_response({:error, _} = error) do
    error
  end

  @spec parse_v3_response(JsonApi.Item.t | {:ok, JsonApi.Item.t} | {:error, any}) :: {:ok, Stops.Stop.t | nil} |
                                                                                     {:error, any}
  defp parse_v3_response({:ok, %JsonApi.Item{} = item}), do: parse_v3_response(item)
  defp parse_v3_response({:error, [%JsonApi.Error{code: "not_found"} | _]}), do: {:ok, nil}
  defp parse_v3_response({:error, _} = error), do: error
  defp parse_v3_response(%JsonApi.Item{} = item) do
    stop = %Stop{
      id: v3_id(item),
      name: v3_name(item),
      address: item.attributes["address"],
      accessibility: merge_accessibility(v3_accessibility(item), item.attributes),
      parking_lots: v3_parking(item),
      station?: is_station?(item),
      has_fare_machine?: Enum.member?(Stop.vending_machine_stations, item.id),
      has_charlie_card_vendor?: Enum.member?(Stop.charlie_card_stations, item.id),
      latitude: item.attributes["latitude"],
      longitude: item.attributes["longitude"]
    }
    {:ok, stop}
  end

  @spec is_station?(JsonApi.Item.t) :: boolean
  defp is_station?(%JsonApi.Item{} = item) do
    item.attributes["location_type"] == 1 or item.relationships["facilities"] != []
  end

  @spec v3_accessibility(JsonApi.Item.t) :: [String.t]
  defp v3_accessibility(item) do
    {escalators, others} = Enum.split_with(item.relationships["facilities"], & &1.attributes["type"] == "ESCALATOR")
    escalators = parse_escalator_direction(escalators)
    other = MapSet.new(others, &facility_atom_from_string(&1.attributes["type"]))
    matching_others = MapSet.intersection(other, MapSet.new(@accessible_facilities))
    Enum.map(escalators ++ MapSet.to_list(matching_others), &Atom.to_string/1)
  end

  @spec parse_escalator_direction([JsonApi.Item.t]) :: [:escalator | :escalator_up | :escalator_down | :escalator_both]
  defp parse_escalator_direction([]), do: []
  defp parse_escalator_direction(escalators) do
    directions =
      escalators
      |> Enum.map(& &1.attributes["properties"])
      |> List.flatten
      |> Enum.filter(& &1["name"] == "direction")
      |> Enum.map(& &1["value"])
    down? = "down" in directions
    up? = "up" in directions
    [do_escalator(down?, up?)]
  end

  defp do_escalator(down?, up?)
  defp do_escalator(true, false), do: :escalator_down
  defp do_escalator(false, true), do: :escalator_up
  defp do_escalator(true, true), do: :escalator_both
  defp do_escalator(false, false), do: :escalator

  @spec v3_parking(JsonApi.Item.t) :: [Stops.Stop.ParkingLot.t]
  defp v3_parking(item) do
    item.relationships["facilities"]
    |> Enum.filter(&(&1.attributes["type"] == "PARKING_AREA"))
    |> Enum.map(&parse_parking_area/1)
  end

  @spec parse_parking_area(JsonApi.Item.t) :: Stops.Stop.ParkingLot.t
  defp parse_parking_area(parking_area) do
    parking_area.attributes["properties"]
    |> Enum.reduce(%{}, &property_acc/2)
    |> Map.put(:name, parking_area.attributes["name"])
    |> Map.put(:id, parking_area.id)
    |> to_parking_lot
  end

  @spec to_parking_lot(map) :: Stops.Stop.ParkingLot.t
  defp to_parking_lot(props) do
    %Stops.Stop.ParkingLot{
      spots: [
        %Stops.Stop.Parking {
          type: "Parking",
          spots: Map.get(props, "capacity", 0),
        },
        %Stops.Stop.Parking {
          type: "Accessible",
          spots: Map.get(props, "capacity-accessible", 0),
        },
      ],
      rate: Map.get(props, "fee-daily"),
      pay_by_phone_id: Map.get(props, "payment-app-id"),
      note: Map.get(props, "note"),
      manager: %Stops.Stop.Manager{
        name: Map.get(props, "operator"),
        email: Map.get(props, "contact"),
        phone: Map.get(props, "contact-phone"),
        website: Map.get(props, "contact-url")
      },
    }
  end

  defp property_acc(property, acc) do
    case property["name"] do
      "payment-form-accepted" ->
        payment = pretty_payment(property["value"])
        Map.update(acc, "payment-form-accepted", [payment], &[payment | &1])
      _ ->
        Map.put(acc, property["name"], property["value"])
    end
  end

  @spec pretty_payment(String.t) :: String.t
  def pretty_payment("cash"), do: "Cash"
  def pretty_payment("check"), do: "Check"
  def pretty_payment("coin"), do: "Coin"
  def pretty_payment("credit-debit-card"), do: "Credit/Debit Card"
  def pretty_payment("e-zpass"), do: "EZ Pass"
  def pretty_payment("invoice"), do: "Invoice"
  def pretty_payment("mobile-app"), do: "Mobile App"
  def pretty_payment("smartcard"), do: "Smart Card"

  @spec merge_accessibility([String.t], %{String.t => any}) :: [String.t]
  defp merge_accessibility(accessibility, stop_attributes)
  defp merge_accessibility(accessibility, %{"wheelchair_boarding" => 0}) do
    # if GTFS says we don't know what the accessibility situation is, then
    # add "unknown" as the first attribute
    ["unknown" | accessibility]
  end
  defp merge_accessibility(accessibility, %{"wheelchair_boarding" => 1}) do
    # make sure "accessibile" is the first list option
    ["accessible" | accessibility]
  end
  defp merge_accessibility(accessibility, _) do
    accessibility
  end

  @type gtfs_facility_type ::
    :elevator |
    :escalator |
    :ramp |
    :elevated_subplatform |
    :fully_elevated_platform |
    :portable_boarding_lift |
    :bridge_plate |
    :parking_area |
    :pick_drop|
    :taxi_stand |
    :bike_storage |
    :tty_phone |
    :electric_car_chargers |
    :fare_vending_retailer |
    :other

  @spec facility_atom_from_string(String.t) :: gtfs_facility_type
  defp facility_atom_from_string("ELEVATOR"), do: :elevator
  defp facility_atom_from_string("ESCALATOR"), do: :escalator
  defp facility_atom_from_string("ESCALATOR_UP"), do: :escalator_up
  defp facility_atom_from_string("ESCALATOR_DOWN"), do: :escalator_down
  defp facility_atom_from_string("ESCALATOR_BOTH"), do: :escalator_both
  defp facility_atom_from_string("RAMP"), do: :ramp
  defp facility_atom_from_string("ELEVATED_SUBPLATFORM"), do: :elevated_subplatform
  defp facility_atom_from_string("FULLY_ELEVATED_PLATFORM"), do: :fully_elevated_platform
  defp facility_atom_from_string("PORTABLE_BOARDING_LIFT"), do: :portable_boarding_lift
  defp facility_atom_from_string("BRIDGE_PLATE"), do: :bridge_plate
  defp facility_atom_from_string("PARKING_AREA"), do: :parking_area
  defp facility_atom_from_string("PICK_DROP"), do: :pick_drop
  defp facility_atom_from_string("TAXI_STAND"), do: :taxi_stand
  defp facility_atom_from_string("BIKE_STORAGE"), do: :bike_storage
  defp facility_atom_from_string("TTY_PHONE"), do: :tty_phone
  defp facility_atom_from_string("ELECTRIC_CAR_CHARGERS"), do: :electric_car_chargers
  defp facility_atom_from_string("FARE_VENDING_RETAILER"), do: :fare_vending_retailer
  defp facility_atom_from_string("FARE_VENDING_MACHINE"), do: :fare_vending_machine
  defp facility_atom_from_string("FARE_MEDIA_ASSISTANT"), do: :fare_media_assistant
  defp facility_atom_from_string("OTHER"), do: :other
end
