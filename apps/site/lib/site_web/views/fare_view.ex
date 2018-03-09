defmodule SiteWeb.FareView do
  use SiteWeb, :view

  alias Fares.{Fare, Summary}

  defdelegate description(fare, assigns), to: SiteWeb.FareView.Description

  @doc "Renders a summary of fares into HTML"
  @spec summarize([Summary.t], Keyword.t) :: Phoenix.HTML.Safe.t
  def summarize(summaries, opts \\ []) do
    render("_summary.html", summaries: summaries, class: opts[:class])
  end

  @doc "Return the reduced fare note for the given fare"
  @spec fare_type_note(Plug.Conn.t, Fare.t) :: Phoenix.HTML.safe | nil
  def fare_type_note(conn, %Fare{reduced: :student}) do
    content_tag :span do
      ["Middle and high school students at participating schools can get a ",
       (link "Student CharlieCard", to: cms_static_page_path(conn, "/fares/reduced/student-charliecards"), data: [turbolinks: "false"]),
       " for discounts on the subway, bus, Commuter Rail, and ferry. College students are not eligible for these discounts, but may be able to purchase a ",
       (link "Semester Pass", to: "https://passprogram.mbta.com/Public/ppinfo.aspx?p=u", data: [turbolinks: "false"]),
       " through their school."]
    end
  end
  def fare_type_note(conn, %Fare{reduced: :senior_disabled}) do
    content_tag :span do
      ["People 65 and older and people with disabilities qualify for reduced fares on the subway, bus, Commuter Rail, and ferry. Seniors must obtain a ",
      (link "Senior CharlieCard", to: cms_static_page_path(conn, "/fares/reduced/senior-charliecard"), data: [turbolinks: "false"]),
      " and people with disabilities must apply for a ",
     (link "Transportation Access Pass (TAP)", to: cms_static_page_path(conn, "/fares/reduced/transportation-access-pass"), data: [turbolinks: "false"]),
      ". People who are blind or have low vision can ride all MBTA services for free with a ",
      (link "Blind Access Card", to: cms_static_page_path(conn, "/fares/reduced/blind-access-charliecard"), data: [turbolinks: "false"]), "."]
    end
  end
  def fare_type_note(_conn, %Fare{reduced: nil, mode: mode}) when mode in [:bus, :subway] do
    content_tag :span do
      ~s(For information about 1-day, 7-day, and monthly passes, click on the "Passes" tab below.)
    end
  end
  def fare_type_note(_conn, %Fare{reduced: nil, mode: :ferry}) do
    content_tag :span do
      ~s(You can buy a ferry ticket after you board the boat, but we recommend buying your ticket or pass in advance.)
    end
  end
  def fare_type_note(_conn, %Fare{reduced: nil, mode: :commuter_rail}) do
    content_tag :span do
      ~s(If you buy a round trip ticket with cash on board the train, it is only valid until the end of service that same day.)
    end
  end
  def fare_type_note(_conn, _fare) do
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
    fare_path(SiteWeb.Endpoint, :show, name, opts)
  end

  @spec callout(Fare.t) :: String.t | iolist
  def callout(%Fare{name: :inner_express_bus}) do
    [Util.AndJoin.and_join(Routes.Route.inner_express()), "."]
  end
  def callout(%Fare{name: :outer_express_bus}) do
    [Util.AndJoin.and_join(Routes.Route.outer_express()), "."]
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
        link("Zones 1A-10", to: fare_path(SiteWeb.Endpoint, :zone)),
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

  @spec clean_city(String.t) :: iodata
  defp clean_city(city) do
    city = city |> String.split("/") |> List.first
    [city, ", MA"]
  end

end
