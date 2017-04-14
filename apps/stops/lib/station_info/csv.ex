defmodule Stops.StationInfo.Csv do
  alias Stops.Stop

  @vending_machine_stations ["place-north", "place-sstat", "place-bbsta", "place-portr", "place-mlmnl",
                             "Lynn", "Worcester", "place-rugg", "place-forhl", "place-jfk", "place-qnctr",
                             "place-brntn"]
                             |> Map.new(&{&1, true})

  @charlie_card_stations [
    "place-alfcl",
    "place-armnl",
    "place-asmnl",
    "place-bbsta",
    "64000",
    "place-forhl",
    "place-harsq",
    "place-north",
    "place-ogmnl",
    "place-pktrm",
    "place-rugg"
  ]
  |> Map.new(&{&1, true})

  def parse_row(row) do
    id = String.strip(row["_gtfs_id"])
    %Stop{
      id: id,
      name: row["_name"],
      note: row["AdditionalNotes"],
      accessibility: accessibility(row),
      address: row["Address"],
      parking_lots: parking_lots(row),
      station?: true,
      has_fare_machine?: Map.get(@vending_machine_stations, id, false),
      has_charlie_card_vendor?: Map.get(@charlie_card_stations, id, false)
    }
  end

  defp accessibility(row) do
    for {type, row_key} <- [accessible: "HandicapAccessible",
                            mini_high: "MiniHighs_Access",
                            mobile_lift: "MobileLift_Access",
                            ramp: "Ramp_Access",
                            elevator: "Elevator_Access",
                            tty_phone: "TTYPhone_Access"],
      row[row_key] == "Yes" do
        Atom.to_string(type)
    end ++ escalator(row)
  end

  defp escalator(%{"Escalator_Access" => "Both"}) do
    ["escalator_both"]
  end
  defp escalator(%{"Escalator_Access" => "Yes"}) do
    ["escalator_both"]
  end
  defp escalator(%{"Escalator_Access" => "Up"}) do
    ["escalator_up"]
  end
  defp escalator(%{"Escalator_Access" => "Down"}) do
    ["escalator_down"]
  end
  defp escalator(_row) do
    []
  end

  defp parking_lots(row) do
    if manager = manager(row) do
      [
        %Stop.ParkingLot{
          spots: parking_spots(row),
          rate: check_na(row["ParkingRate"]),
          note: row["Comments"],
          manager: manager}
      ]
    else
      []
    end
  end

  defp manager(%{"ManagedByLabel" => label} = row)
  when label != "" and label != "N/A" do
    %Stop.Manager{
      name: String.strip(label),
      email: row["ManagedByEmail"],
      website: row["ManagedByWeb"],
      phone: row["ManagedByPhone"]
    }
  end
  defp manager(_row) do
    nil
  end

  defp parking_spots(row) do
    for {type, row_key} <- [basic: "SpacesAvailable",
                            accessible: "AccessibleParkingSpaces",
                            bike: "BikeSpaces"],
      spot_count(row[row_key]) do
        %Stop.Parking{
          type: Atom.to_string(type),
          spots: spot_count(row[row_key])
        }
    end
  end

  defp spot_count(binary) do
    case Integer.parse(String.replace(binary, ",", "")) do
      {0, _} -> nil
      :error -> nil
      {count, _} -> count
    end
  end

  defp check_na(""), do: nil
  defp check_na("N/A"), do: nil
  defp check_na(value), do: value
end
