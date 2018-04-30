defmodule SiteWeb.FareView.Description do
  alias Fares.Fare
  import Phoenix.HTML.Tag, only: [content_tag: 2]
  import Util.AndJoin

  @spec description(Fare.t, map()) :: Phoenix.HTML.unsafe
  def description(%Fare{mode: :commuter_rail, duration: :single_trip, name: name}, _assigns) do
    ["Valid for travel on Commuter Rail ", valid_commuter_zones(name), " only."]
  end
  def description(%Fare{mode: :commuter_rail, duration: :round_trip, name: name}, _assigns) do
    ["Valid for travel on Commuter Rail ", valid_commuter_zones(name), " only."]
  end
  def description(%Fare{mode: :commuter_rail, duration: :month, media: [:mticket], name: name}, _assigns) do
    ["Valid for one calendar month of travel on the commuter rail ",
     valid_commuter_zones(name),
     " only."
    ]
  end
  def description(%Fare{mode: :commuter_rail, duration: :month, additional_valid_modes: [:bus], name: name}, _assigns) do
    ["Valid for one calendar month of unlimited travel on Commuter Rail ",
     valid_commuter_zones(name),
     " as well as Local Bus."]
  end
  def description(%Fare{mode: :commuter_rail, duration: :month, name: name}, _assigns) do
    ["Valid for one calendar month of unlimited travel on Commuter Rail ",
     valid_commuter_zones(name),
     " as well as Local Bus, Subway, and the Charlestown Ferry."]
  end
  def description(%Fare{mode: :ferry, duration: duration}, %{origin: origin, destination: destination}) when duration in [:round_trip, :single_trip, :day, :week] do
    [
      "Valid between ",
      origin.name,
      " and ",
      destination.name,
      " only."
    ]
  end
  def description(%Fare{mode: :ferry, duration: duration} = fare, _assigns) when duration in [:round_trip, :single_trip, :day, :week] do
    [
      "Valid for the ",
      Fares.Format.name(fare),
      " only."
    ]
  end
  def description(%Fare{mode: :ferry, duration: :month, media: [:mticket]} = fare, _assigns) do
       [
         "Valid for one calendar month of unlimited travel on the ",
         Fares.Format.name(fare),
         " only."
       ]
  end
  def description(%Fare{mode: :ferry, duration: :month} = fare, _assigns) do
    [content_tag(:div, "Valid for 1 calendar month on:"),
     content_tag(:ul, boston_ferry_pass_modes(fare))
    ]
  end
  def description(%Fare{name: name, duration: :single_trip, media: [:charlie_ticket, :cash]}, _assigns)
  when name in [:inner_express_bus, :outer_express_bus] do
    "No free or discounted transfers."
  end
  def description(%Fare{mode: :subway, media: media, duration: :single_trip} = fare, _assigns)
  when media != [:charlie_ticket, :cash] do

    [
      "Travel on all subway lines, SL1, SL2, and SL3. ",
      transfers(fare)
    ]
  end
  def description(%Fare{mode: :subway, media: [:charlie_ticket, :cash]}, _assigns) do
    "CharlieTickets include 1 free transfer to any SL route within 2 hours of original ride. No transfers with cash."
  end
  def description(%Fare{mode: :bus, media: [:charlie_ticket, :cash]}, _assigns) do
    "CharlieTickets include 1 free transfer to another Local Bus, SL4, or SL5. No transfers with cash."
  end
  def description(%Fare{mode: :subway, duration: :month, reduced: :student}, _assigns) do
    modes = ["Local Bus", "Subway", "Commuter Rail Zone 1A (CharlieTicket only)"]
            |> Enum.map(&content_tag(:li, &1))

    [content_tag(:div, "Unlimited travel for 1 calendar month on:"),
     content_tag(:ul, modes)
    ]
  end
  def description(%Fare{mode: :subway, duration: :month}, _assigns) do
    modes = ["Local Bus", "Subway", "Commuter Rail Zone 1A (CharlieTicket only)"]
            |> Enum.map(&content_tag(:li, &1))

    [content_tag(:div, "Unlimited travel for 1 calendar month on:"),
     content_tag(:ul, modes)
    ]
  end
  def description(%Fare{mode: :subway, duration: duration}, _assigns) when duration in [:day, :week] do
    modes = ["Local Bus", "Subway", "Commuter Rail Zone 1A (CharlieTicket only)", "Charlestown Ferry (CharlieTicket only)"]
            |> Enum.map(&content_tag(:li, &1))

    [content_tag(:div, "Unlimited travel for #{duration_string_header(duration)}* on:"),
     content_tag(:ul, modes),
     "*CharlieTickets are valid for ",
     duration_string_body(duration),
     " from purchase. CharlieCards are valid for ",
     duration_string_body(duration),
     " after first use."
    ]
  end
  def description(%Fare{name: :local_bus, duration: :month}, _assigns) do
    modes = ["Local Bus (not including routes SL1, SL2, or SL3)"]
            |> Enum.map(&content_tag(:li, &1))

    [content_tag(:div, "Unlimited travel for 1 calendar month on:"),
     content_tag(:ul, modes)
    ]
  end
  def description(%Fare{name: :inner_express_bus, media: [:charlie_card, :charlie_ticket], duration: :month}, _assigns) do
    modes = ["Inner Express Bus", "Local Bus", "Subway",
             "Commuter Rail Zone 1A (CharlieTicket or pre-printed CharlieCard with valid date only)",
             "Charlestown Ferry (CharlieTicket or pre-printed CharlieCard with valid date only)"]
            |> Enum.map(&content_tag(:li, &1))

    [content_tag(:div, "Unlimited travel for 1 calendar month on:"),
     content_tag(:ul, modes)
    ]

  end
  def description(%Fare{name: :inner_express_bus, duration: :month}, _assigns) do
    ["Unlimited travel for one calendar month on the Inner Express Bus",
     "Local Bus",
     "Subway."
    ] |> and_join
  end
  def description(%Fare{name: :outer_express_bus, media: [:charlie_card, :charlie_ticket], duration: :month}, _assigns) do
    modes = ["Outer Express Bus", "Inner Express Bus", "Local Bus", "Subway",
             "Commuter Rail Zone 1A (CharlieTicket or pre-printed CharlieCard with valid date only)",
             "Charlestown Ferry (CharlieTicket or pre-printed CharlieCard with valid date only)"
            ]
            |> Enum.map(&content_tag(:li, &1))

    [content_tag(:div, "Unlimited travel for 1 calendar month on:"),
     content_tag(:ul, modes)
    ]
  end
  def description(%Fare{name: :outer_express_bus, duration: :month}, _assigns) do
    ["Unlimited travel for one calendar month on the Outer Express Bus as well as the Inner Express Bus",
     "Local Bus",
     "Subway.",
    ] |> and_join
  end
  def description(%Fare{name: :free_fare, mode: :bus, media: []}, _assigns) do
    ["Travel on all local bus routes, SL4 and SL5"]
  end
  def description(%Fare{mode: :bus, media: media, name: name} = fare, _assigns)
  when media != [:charlie_ticket, :cash] do
    [
      bus_description_intro(name),
      transfers(fare)
    ]
  end
  def description(%Fare{name: :ada_ride}, _assigns) do
    [
      content_tag(:p, "Destination is:"),
      content_tag(:ul, [
        content_tag(:li, [
          "Less than ", {:safe, ["&frac34;"]}, " mile from an active MBTA bus or subway stop/station ",
            content_tag(:strong, "OR")]),
        content_tag(:li, "In the core RIDE service area")]),
      content_tag(:p, "You may also pay a premium fare if you:")
    ]
  end
  def description(%Fare{name: :premium_ride}, _assigns) do
    [
      content_tag(:p, "Destination is:"),
      content_tag(:ul, [
        content_tag(:li, [
          "More than ", {:safe, ["&frac34;"]}, " mile from an active MBTA bus or subway stop/station ",
            content_tag(:strong, "OR")]),
        content_tag(:li, "Not within the core RIDE service area")]),
      content_tag(:p, "You may also pay a premium fare if you:"),
      content_tag(:ul, [
        content_tag(:li, "Request same-day service changes"),
        content_tag(:li, "Change your reservation after 5 PM for service the next day")]
      )
     ]
  end
  def description(%Fare{name: :free_fare}, _assigns) do
    ["Inbound SL1 travel from any airport stop is free."]
  end

  defp boston_ferry_pass_modes(fare) do
    [Fares.Format.name(fare),
     "Commuter Rail Zone 1A",
     "Subway",
     "Local Bus"
    ]
    |> Enum.map(&content_tag(:li, &1))
  end

  defp bus_description_intro(name) when name in [:inner_express_bus, :outer_express_bus], do: ""
  defp bus_description_intro(_), do: "Travel on all local bus routes, SL4 and SL5. "

  defp duration_string_body(:day), do: "24 hours"
  defp duration_string_body(:week), do: "7 days"

  defp duration_string_header(:day), do: "1 day"
  defp duration_string_header(:week), do: "7 days"

  defp valid_commuter_zones({:zone, "1A"}) do
    "in Zone 1A"
  end
  defp valid_commuter_zones({:zone, final}) do
    ["from Zones 1A-", final]
  end
  defp valid_commuter_zones({:interzone, total}) do
    ["between ", total, " zones outside of Zone 1A"]
  end
  defp valid_commuter_zones(:foxboro) do
    "to Gillette Stadium for special events"
  end

  def transfers(fare) do
    # used to generate the list of transfer fees for a a given fare.
    # Transfers <= 0 are considered free.
    {paid, free} = fare.name
                   |> valid_transfers()
                   |> Enum.split_with(&transfers_filter(&1, fare))
    [
      free_transfers(free),
      content_tag(:ul, Enum.map(paid, &transfers_map(&1, fare)))
    ]
  end

  defp valid_transfers(:inner_express_bus = name) do
    [subway: "subway",
     local_bus: local_bus_text(name),
     outer_express_bus: "Outer Express Bus"]
  end
  defp valid_transfers(:outer_express_bus = name) do
    [subway: "subway",
     local_bus: local_bus_text(name)]
  end
  defp valid_transfers(name) do
    [subway: "subway",
     local_bus: local_bus_text(name),
     inner_express_bus: "Inner Express Bus",
     outer_express_bus: "Outer Express Bus"]
  end

  defp local_bus_text(:subway), do: "Local Bus, SL4, or SL5"
  defp local_bus_text(:local_bus), do: "another Local Bus, SL4, or SL5"
  defp local_bus_text(:outer_express_bus), do: "Local Bus, Inner Express Bus, or any SL route"
  defp local_bus_text(:inner_express_bus), do: "Local Bus, or any SL route"

  defp transfers_filter({name, _}, fare) do
    other_fare = transfers_other_fare(name, fare)
    other_fare.cents > fare.cents
  end

  defp free_transfers([]) do
    []
  end
  defp free_transfers(names_and_texts) do
    ["Includes 1 free transfer to ",
     names_and_texts
     |> Enum.map(&elem(&1, 1))
     |> Enum.join(", "),
     " within 2 hours of your original ride."
    ]
  end

  defp transfers_map({name, text}, fare) do
    other_fare = transfers_other_fare(name, fare)
    content_tag(:li, ["Transfer to ", text, ": ", Fares.Format.price(other_fare.cents - fare.cents)])
  end

  defp transfers_other_fare(name, fare) do
    case {fare, name, Fares.Repo.all(name: name, media: fare.media, duration: fare.duration)} do
      {_, _, [other_fare]} -> other_fare
    end
  end
end
