defmodule SiteWeb.FareView do
  use SiteWeb, :view

  alias Fares.{Fare, Summary}
  alias SiteWeb.PartialView.SvgIconWithCircle

  defdelegate description(fare, assigns), to: SiteWeb.FareView.Description

  @doc "Renders a summary of fares into HTML"
  @spec summarize([Summary.t], Keyword.t) :: Phoenix.HTML.Safe.t
  def summarize(summaries, opts \\ []) do
    render("_summary.html", summaries: summaries, class: opts[:class])
  end

  @doc "Return the reduced fare note for the given fare"
  @spec fare_type_note(Plug.Conn.t, Fare.t) :: Phoenix.HTML.safe | nil
  def fare_type_note(conn, %Fare{reduced: :student}) do
    [
      content_tag(:span,
        ["Middle and high school students with an MBTA-issued ",
         (link "Student CharlieCard", to: cms_static_page_path(conn, "/fares/reduced/student-charliecards"), data: [turbolinks: "false"]),
         " or a current school ID are eligible for reduced Commuter Rail fares. Students with M7 CharlieCards can travel free up to Zone 2 and are eligible for reduced interzone fares."]),
      content_tag(:p,
        ["College students are not eligible for these discounts, but may be able to purchase a ",
         (link "Semester Pass", to: "https://passprogram.mbta.com/Public/ppinfo.aspx?p=u", data: [turbolinks: "false"]),
         " through their school."])
    ]
  end
  def fare_type_note(conn, %Fare{reduced: :senior_disabled}) do
    content_tag :span do
      ["Seniors are eligible for reduced fares on the subway, bus, Commuter Rail, and ferry with a ",
      (link "Senior CharlieCard", to: cms_static_page_path(conn, "/fares/reduced/senior-charliecard"), data: [turbolinks: "false"]),
      " or state-issued ID. People with disabilities are eligible for reduced fares with a ",
      (link "Transportation Access Pass (TAP)", to: cms_static_page_path(conn, "/fares/reduced/transportation-access-pass"), data: [turbolinks: "false"]),
      ". People who are blind or have low vision ride all MBTA services for free with a ",
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
    anchor = cond do
      duration in ~w(day week)a -> "#7-day"
      duration in ~w(month)a -> "#monthly"
      true -> ""
    end
    do_summary_url(subway_or_bus, anchor)
  end
  def summary_url(%Summary{modes: [mode | _]}) do
    do_summary_url(mode)
  end

  @spec do_summary_url(atom, String.t) :: String.t
  defp do_summary_url(name, anchor \\ "") do
    fare_path(SiteWeb.Endpoint, :show, SiteWeb.StaticPage.convert_path(name) <> "-fares") <> anchor
  end

  @spec callout(Fare.t) :: String.t | iolist
  def callout(%Fare{name: :inner_express_bus}) do
    [Util.AndOr.join(Routes.Route.inner_express(), :and), "."]
  end
  def callout(%Fare{name: :outer_express_bus}) do
    [Util.AndOr.join(Routes.Route.outer_express(), :and), "."]
  end
  def callout(%Fare{}), do: ""

  def callout_description(%Fare{name: name}) when name == :outer_express_bus or name == :inner_express_bus do
    "Routes "
  end
  def callout_description(%Fare{}), do: ""

  @spec vending_machine_stations :: [Phoenix.HTML.Safe.t]
  def vending_machine_stations do
    stop_link_list(Stops.Repo.vending_machine_stations())
  end

  def charlie_card_stations do
    stop_link_list(Stops.Repo.charlie_card_stations())
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
        svg_icon_with_circle(%SvgIconWithCircle{icon: mode, size: :small})
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
  @spec origin_destination_description(Plug.Conn.t, :commuter_rail | :ferry) :: Phoenix.HTML.Safe.t
  def origin_destination_description(conn, :commuter_rail) do
    [
      content_tag :p do
        [
          "Learn about ",
          link("$10 summer weekends on Commuter Rail", to: cms_static_page_path(conn, "/weekendrail")),
          "."
        ]
      end,
      content_tag :p do
        [
          "Select your origin and destination stations from the drop-down lists below to find your Commuter Rail fare."
        ]
      end
    ]
  end
  def origin_destination_description(_, :ferry) do
    content_tag :p, do: "Select your origin and destination stops from the drop-down lists below to find your ferry fare."
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

  @spec cta_for_mode(Plug.Conn.t, :commuter_rail | :ferry) :: Phoenix.HTML.Safe.t
  def cta_for_mode(conn, mode) do
    name = Routes.Route.type_name(mode)
    mode = mode
          |> Atom.to_string()
          |> String.replace("_", "-")
    url = "/fares/" <> mode <> "-fares"
    content_tag :p, do: [
      link(["Learn more about ", name, " fares ", fa("arrow-right")], to: cms_static_page_path(conn, url))
    ]
  end
end
