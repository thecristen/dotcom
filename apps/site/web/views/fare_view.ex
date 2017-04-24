defmodule Site.FareView do
  use Site.Web, :view

  alias Fares.{Fare, Summary}

  defdelegate description(fare, assigns), to: Site.FareView.Description

  @doc "Renders a summary of fares into HTML"
  @spec summarize([Summary.t], Keyword.t) :: Phoenix.HTML.Safe.t
  def summarize(summaries, opts \\ []) do
    render("_summary.html", summaries: summaries, class: opts[:class])
  end

  @doc "Return the reduced fare note for the given fare"
  @spec fare_type_note(Fare.t) :: Phoenix.HTML.Safe.t | nil
  def fare_type_note(%Fare{reduced: :student}) do
    content_tag :span do
      ["Middle and high school students are eligible for reduced fares on Subway. In order to receive a reduced fare, students must use a ",
       (link "Student CharlieCard ", to: fare_path(Site.Endpoint, :show, :reduced)<>"#students", data: [turbolinks: "false"]),
       "issued by their school. Student discounts apply to One Way fares only. Discounts for passes are not available. College students may
       be eligible for reduced fares through a Semester Pass Program. For more information, please contact an administrator at your school."]
    end
  end
  def fare_type_note(%Fare{reduced: :senior_disabled}) do
    content_tag :span do
      ["People aged 65 years or older and persons with disabilities qualify for a reduced fare on Bus and Subway. Seniors must obtain a ",
      (link "Senior CharlieCard ", to: fare_path(Site.Endpoint, :show, :reduced), data: [turbolinks: "false"]),
      "and persons with disabilities must apply for a ",
     (link "Transportation Access Pass (TAP) ", to: fare_path(Site.Endpoint, :show, :reduced)<>"#reduced-disability", data: [turbolinks: "false"]),
      "in order to receive a reduced fare. Discounts apply to One Way fares only. Discounts for passes are not available."]
    end
  end
  def fare_type_note(%Fare{reduced: nil, mode: mode}) when mode in [:bus, :subway] do
    content_tag :span do
      "If you would like information on purchasing more than one trip, click on the “Passes” tab below."
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

  @spec summary_url(Summary.t) :: String.t
  def summary_url(%Summary{url: url}) when not is_nil(url), do: url
  def summary_url(%Summary{modes: [subway_or_bus | _], duration: duration}) when subway_or_bus in [:subway, :bus] do
    opts = if duration in ~w(day week month)a do
      [filter: "passes"]
    else
      []
    end
    do_summary_url(:bus_subway, opts)
  end
  def summary_url(%Summary{modes: [mode | _]}) do
    do_summary_url(mode)
  end

  defp do_summary_url(name, opts \\ []) do
    fare_path(Site.Endpoint, :show, name, opts)
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

  @doc "Returns the svg icons for the modes passed in"
  @spec fare_mode_icons([:bus | :subway | :commuter_rail | :ferry]) :: Phoenix.HTML.Safe.t
  def fare_mode_icons(modes) do
    content_tag :span, class: "payment-method-modes no-wrap" do
      for mode <- modes do
        svg_icon_with_circle(%SvgIconWithCircle{icon: mode, class: "icon-small"})
      end
    end
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
  @spec destination_key_stops([Stops.Stop.t], [Stops.Stop.t]) :: [Stops.Stop.t]
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
        "Your Commuter Rail fare will depend on which stops you board and exit the train. Stops are categorized into ",
        link("Zones 1A-10", to: "http://www.mbta.com/uploadedimages/Fares_and_Passes_v2/Commuter_Rail/Commuter_Rail_List/Cr-Zones-Web.jpg"),
        ". Enter two stops below to find your trip's exact fare."
      ]
    end
  end
  def origin_destination_description(:ferry) do
    content_tag :p, do: "Ferry fares depend on your origin and destination."
  end

  def charlie_card_store_link(conn) do
    content_tag :span, class: "no-wrap" do
      [
        "(",
        link("view details", to: Path.join(fare_path(conn, :show, :charlie_card), "#store"), "data-turbolinks": "false"),
        ")"
      ]
    end
  end
end
