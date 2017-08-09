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
    id = String.trim(row["_gtfs_id"])
    %Stop{
      id: id,
      name: ensure_value(row["_name"]),
      note: ensure_value(row["AdditionalNotes"]),
      accessibility: accessibility(row),
      address: ensure_value(row["Address"]),
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
          rate: ensure_value(row["ParkingRate"]),
          note: ensure_value(row["Comments"]),
          manager: manager}
      ]
    else
      []
    end
  end

  defp manager(%{"ManagedByLabel" => label} = row) do
    case ensure_value(label) do
      nil ->
        nil
      valid_label ->
        %Stop.Manager{
          name: valid_label,
          email: ensure_value(row["ManagedByEmail"]),
          website: ensure_value(row["ManagedByWeb"]),
          phone: ensure_value(row["ManagedByPhone"])
        }
    end
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

  defp ensure_value("N/A"), do: nil
  defp ensure_value(nil), do: nil
  defp ensure_value(value) do
    case String.trim(value) do
      "" -> nil
      trimmed_val -> trimmed_val
    end
  end
end
