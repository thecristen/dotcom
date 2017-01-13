defmodule Site.FareView do
  use Site.Web, :view

  alias Fares.Fare

  defdelegate description(fare, assigns), to: Site.FareView.Description

  @doc "Renders a summary of fares into HTML"
  @spec summarize([Fare.Summary.t]) :: Phoenix.HTML.Safe.t
  def summarize(summaries) do
    render("_summary.html", summaries: summaries)
  end

  @doc "Return the reduced fare note for the given fare"
  @spec fare_type_note(Fare.t) :: Phoenix.HTML.Safe.t | nil
  def fare_type_note(%Fare{reduced: :student}) do
    content_tag :span do
      "Middle and high school students are eligible for reduced fares on Subway. In order to receive a reduced fare, students must use a Student CharlieCard issued by their school. Student discounts apply to One Way fares only -- discounts for passes not available. College students may be eligible for reduced fares through a Semester Pass Program. For more information, please contact an administrator at your school."
    end
  end
  def fare_type_note(%Fare{reduced: :senior_disabled}) do
    content_tag :span do
      ["People 65 or older and persons with disabilities qualify for a reduced fare on Bus and Subway. Seniors must obtain a Senior CharlieCard and persons with disabilities must apply for a ",
     (link "Transportation Access Pass (TAP) ", to: fare_path(Site.Endpoint, :show, :reduced)<>"#reduced-disability", data: [turbolinks: "false"]),
      "in order to receive a reduced fare. Discounts apply to One Way fares only -- discounts for passes not available."]
    end
  end
  def fare_type_note(%Fare{reduced: nil, mode: mode}) when mode in [:bus, :subway] do
    content_tag :span do
      "To view prices and details for fare passes, click on the “Passes” tab below."
    end
  end
  def fare_type_note(%Fare{reduced: nil, mode: :ferry}) do
    content_tag :span do
      "You may pay for your Ferry fare on-board if there is no ticket office at your terminal."
    end
  end
  def fare_type_note(%Fare{reduced: nil, mode: :commuter_rail}) do
    content_tag :span do
      "If you pay for a Round Trip with cash on-board, your ticket for your return trip will only be valid until the end of service that same day."
    end
  end
  def fare_type_note(_) do
    nil
  end

  @spec callout(Fare.t) :: String.t | iolist
  def callout(%Fare{name: :inner_express_bus}) do
    AndJoin.and_join ~w(170 325 326 351 424 426 428 434 449 450 459 501 502 504
     553 554 558.)
  end
  def callout(%Fare{name: :outer_express_bus}) do
    AndJoin.and_join ~w(352 354 505.)
  end
  def callout(%Fare{}), do: ""

  def callout_description(%Fare{name: name}) when name == :outer_express_bus or name == :inner_express_bus do
    "Travels on Routes: "
  end
  def callout_description(%Fare{}), do: ""

  @spec vending_machine_stations :: [Phoenix.HTML.Safe.t]
  def vending_machine_stations do
    Stops.Repo.stations
    |> Enum.filter(fn stop -> stop.has_fare_machine? end)
    |> stop_link_list
  end

  def charlie_card_stations do
    Stops.Repo.stations
    |> Enum.filter(fn stop -> stop.has_charlie_card_vendor? end)
    |> stop_link_list
  end

  defp stop_link_list(stops) do
    stops
    |> Enum.map(&stop_link/1)
    |> Enum.intersperse(", ")
  end

  @spec update_fare_type(Plug.Conn.t, Fare.reduced) :: Plug.Conn.t
  def update_fare_type(conn, reduced_type) do
    update_url(conn, fare_type: reduced_type)
  end

  @doc "Returns the svg icons for the modes passed in"
  @spec fare_mode_icons([:bus | :subway | :commuter_rail | :ferry]) :: Phoenix.HTML.Safe.t
  def fare_mode_icons(modes) do
    content_tag :span, class: "payment-method-modes no-wrap" do
      for mode <- modes do
        svg_icon_with_circle(%SvgIconWithCircle{icon: mode, class: "icon-small"})
      end
    end
  end
  @doc "Returns image description and image path"
  @spec reduced_image(:student | :senior_disabled | nil) :: [{String.t, String.t}]
  def reduced_image(:student) do
    [{"Back of Student CharlieCard","/images/student-charlie-back.jpg"}, {"Front of Student CharlieCard", "/images/student-charlie.jpg"}]
  end
  def reduced_image(:senior_disabled) do
    [{"Transportation Access Pass", "/images/transportation-access-card.jpg"}, {"Senior CharlieCard","/images/senior-id.jpg"}]
  end
  def reduced_image(_) do
    []
  end

  @doc "Display name for given fare"
  @spec format_name(Fare.t, map()) :: Phoenix.HTML.Safe.t
  def format_name(%Fare{mode: :ferry} = base_fare, %{origin: origin, destination: destination}) do
    content_tag :span do
      [
        origin.name,
        " ",
        fa("arrow-right"),
        " ",
        destination.name,
        " ",
        content_tag(:span, Fares.Format.duration(base_fare), class: "no-wrap")
      ]
    end
  end
  def format_name(base_fare, _assigns) do
    Fares.Format.full_name(base_fare)
  end

  @doc "Filter out key stops that are not in possible destinations"
  @spec destination_key_stops([Schedules.Stop.t], [Schedules.Stop.t]) :: [Schedules.Stop.t]
  def destination_key_stops(destination_stops, key_stops) do
    key_stop_ids = Enum.map(key_stops, &(&1.id))
    destination_stops
    |> Enum.filter(&(&1.id in key_stop_ids))
  end

  @doc "Summary copy for describing origin-destination modes."
  @spec origin_destination_description(:commuter_rail | :ferry) :: Phoenix.HTML.Safe.t
  def origin_destination_description(:commuter_rail) do
    content_tag :p do
      [
        "Fares for the Commuter Rail are separated into zones that depend on your origin and destination ",
        link("(view map of fare zones)", to: "http://www.mbta.com/uploadedimages/Fares_and_Passes_v2/Commuter_Rail/Commuter_Rail_List/Cr-Zones-Web.jpg"),
        "."
      ]
    end
  end
  def origin_destination_description(:ferry) do
    content_tag :p, do: "Ferry fares depend on your origin and destination."
  end
end
