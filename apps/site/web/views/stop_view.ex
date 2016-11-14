defmodule Site.StopView do
  use Site.Web, :view

  alias Fares.Summary

  @bus_subway_filters [[name: :subway, duration: :single_trip, reduced: nil],
                        [name: :local_bus, duration: :single_trip, reduced: nil],
                        [name: :subway, duration: :week, reduced: nil],
                        [name: :subway, duration: :month, reduced: nil]]

  @bus_only_filters [[name: :local_bus, duration: :single_trip, reduced: nil],
                       [name: :subway, duration: :week, reduced: nil],
                       [name: :subway, duration: :month, reduced: nil]]

  @subway_only_filters [[name: :subway, duration: :single_trip, reduced: nil],
                       [name: :subway, duration: :week, reduced: nil],
                       [name: :subway, duration: :month, reduced: nil]]

  @ferry_fare_filters [[mode: :ferry, duration: :single_trip, reduced: nil],
                      [mode: :ferry, duration: :month, reduced: nil]]

  @origin_stations ["place-north", "place-sstat", "place-rugg", "place-bbsta"]

  @doc "Specify the mode each type is associated with"
  @spec fare_group(atom) :: String.t
  def fare_group(:bus), do: "bus_subway"
  def fare_group(:subway), do: "bus_subway"
  def fare_group(type), do: Atom.to_string(type)

  def location(stop) do
    case stop.latitude do
      nil -> URI.encode(stop.address, &URI.char_unreserved?/1)
      _ -> "#{stop.latitude},#{stop.longitude}"
    end
  end

  def pretty_accessibility("tty_phone"), do: "TTY Phone"
  def pretty_accessibility("escalator_both"), do: "Escalator (Both)"
  def pretty_accessibility(accessibility) do
    accessibility
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  def optional_li(""), do: ""
  def optional_li(nil), do: ""
  def optional_li(value) do
    content_tag :li, value
  end

  def optional_link("", _) do
    nil
  end
  def optional_link(href, value) do
    content_tag(:a, value, href: external_link(href), target: "_blank")
  end

  @spec external_link(String.t) :: String.t
  @doc "Adds protocol if one is needed"
  def external_link(href = <<"http://", _::binary>>), do: href
  def external_link(href = <<"https://", _::binary>>), do: href
  def external_link(href), do: "http://" <> href

  def sort_parking_spots(spots) do
    spots
    |> Enum.sort_by(fn %{type: type} ->
      case type do
        "basic" -> 0
        "accessible" -> 1
        _ -> 2
      end
    end)
  end

  @spec ferry_summaries() :: [Summary.T]
  @doc "Ferry fare summaries for given filters"
  def ferry_summaries() do
    @ferry_fare_filters |> Enum.flat_map(&Fares.Repo.all/1) |> Fares.Format.summarize(:ferry)
  end

  @spec bus_subway_summaries([atom]) :: [Summary.T]
  @doc "Returns the bus and subway filters for the given types"
  def bus_subway_summaries(types) do
    filters = cond do
                :subway in types && :bus in types -> @bus_subway_filters
                :bus in types -> @bus_only_filters
                true -> @subway_only_filters
              end
    summaries_for_filters(filters)
  end

  @spec commuter_summaries({atom, String.t}) :: [Summary.T]
  @doc "Returns the summarized commuter fares for the given zone"
  def commuter_summaries(zone_name) do
    commuter_filters =  [[mode: :commuter, duration: :single_trip, reduced: nil, name: zone_name],
                         [mode: :commuter, duration: :month, media: [:commuter_ticket], reduced: nil, name: zone_name]]
    commuter_mode_only = fn(summary) -> %{summary | modes: [:commuter]} end
    summaries_for_filters(commuter_filters) |> Enum.map(commuter_mode_only)
  end

  @spec format_accessibility(String.t, [String.t]) :: Phoenix.HTML.Safe.t
  @doc "Describes a given station with the given accessibility features"
  def format_accessibility(name, nil), do: content_tag(:em, "No accessibility information available for #{name}")
  def format_accessibility(name, []), do: content_tag(:em, "No accessibility information available for #{name}")
  def format_accessibility(name, ["accessible"]) do
    content_tag(:span, "#{name} is an accessible station. Accessible stations can be accessed by wheeled mobility devices.")
  end
  def format_accessibility(name, _features), do: content_tag(:span, "#{name} has the following accessibility features:")

  @spec show_fares?(Stop.t) :: boolean
  @doc "Determines if the fare information for the given stop should be displayed"
  def show_fares?(stop) do
    !stop.id in @origin_stations
  end

  @spec summaries_for_filters([keyword()]) :: [Summary.T]
  defp summaries_for_filters(filters) do
    filters |> Enum.flat_map(&Fares.Repo.all/1) |> Fares.Format.summarize(:bus_subway)
  end

  def parking_type("basic"), do: "Parking"
  def parking_type(type), do: type |> String.capitalize

  @spec template_for_tab(String.t) :: String.t
  @doc "Returns the template to be rendered for the given tab"
  def template_for_tab("info"), do: "_info.html"
  def template_for_tab(_tab), do: "_schedule.html"

  @spec tab_class(String.t, String.t) :: String.t
  @doc "Given a station tab, and the selected tab, returns the CSS class for the given station tab"
  def tab_class(tab, tab), do: "stations-tab stations-tab-selected"
  def tab_class("schedule", nil), do: "stations-tab stations-tab-selected"
  def tab_class(_, _), do: "stations-tab"
end
