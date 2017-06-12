defmodule Site.StopView do
  use Site.Web, :view

  alias Stops.Stop
  alias Routes.Route
  alias Fares.RetailLocations.Location

  @origin_stations ["place-north", "place-sstat", "place-rugg", "place-bbsta"]

  @doc "Specify the mode each type is associated with"
  @spec fare_group(atom) :: String.t
  def fare_group(:bus), do: "bus_subway"
  def fare_group(:subway), do: "bus_subway"
  def fare_group(type), do: Atom.to_string(type)

  @spec location(Stops.Stop.t) :: String.t
  def location(%Stops.Stop{latitude: nil, address: address}), do: URI.encode(address, &URI.char_unreserved?/1)
  def location(%Stops.Stop{latitude: lat, longitude: lng}), do: "#{lat},#{lng}"

  @spec pretty_accessibility(String.t) :: String.t
  def pretty_accessibility("tty_phone"), do: "TTY Phone"
  def pretty_accessibility("escalator_both"), do: "Escalator (Both)"
  def pretty_accessibility(accessibility) do
    accessibility
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  @spec sort_parking_spots([Stops.Stop.Parking.t]) :: [Stops.Stop.Parking.t]
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

  @spec render_alerts([Alerts.Alert], DateTime.t, Stop.t) :: Phoenix.HTML.safe | String.t
  def render_alerts(stop_alerts, date, stop) do
    Site.AlertView.modal alerts: stop_alerts, hide_t_alerts: true, time: date, route: %{id: stop.id |> String.replace(" ", "-"), name: stop.name}
  end

  @spec fare_mode([atom]) :: atom
  @doc "Determine what combination of bus and subway are present in given types"
  def fare_mode(types) do
    cond do
      :subway in types && :bus in types -> :bus_subway
      :subway in types -> :subway
      :bus in types -> :bus
    end
  end

  @spec aggregate_routes([map()]) :: [map()]
  @doc "Combine multipe routes on the same subway line"
  def aggregate_routes(routes) do
    routes
    |> Enum.map(& %{&1 | id: normalize_route(&1)})
    |> Enum.uniq_by(&(&1.id))
  end

  @spec normalize_route(Route.t) :: String.t
  def normalize_route(%Route{id: "Green" <> _rest}), do: "Green"
  def normalize_route(%Route{id: id}), do: id

  @spec accessibility_info(Stop.t) :: [Phoenix.HTML.Safe.t]
  @doc "Accessibility content for given stop"
  def accessibility_info(stop) do
    [(content_tag :p, format_accessibility_text(stop.name, stop.accessibility)),
    format_accessibility_options(stop)]
  end

  @spec format_accessibility_options(Stop.t) :: Phoenix.HTML.safe | String.t
  defp format_accessibility_options(stop) do
    if stop.accessibility && !Enum.empty?(stop.accessibility) do
      content_tag :p do
        stop.accessibility
        |> Enum.filter(&(&1 != "accessible"))
        |> Enum.map(&pretty_accessibility/1)
        |> Enum.join(", ")
      end
    else
      ""
    end
  end

  @spec format_accessibility_text(String.t, [String.t]) :: Phoenix.HTML.Safe.t
  defp format_accessibility_text(name, nil), do: content_tag(:em, "No accessibility information available for #{name}")
  defp format_accessibility_text(name, []), do: content_tag(:em, "No accessibility information available for #{name}")
  defp format_accessibility_text(name, ["accessible"]) do
    content_tag(:span, "#{name} is an accessible station.")
  end
  defp format_accessibility_text(name, _features), do: content_tag(:span, "#{name} has the following accessibility features:")

  @spec origin_station?(Stop.t) :: boolean
  def origin_station?(stop) do
    stop.id in @origin_stations
  end

  @spec fare_surcharge?(Stop.t) :: boolean
  def fare_surcharge?(stop) do
    stop.id in ["place-bbsta", "place-north", "place-sstat"]
  end

  @spec parking_type(String.t) :: String.t
  def parking_type("basic"), do: "Parking"
  def parking_type(type), do: type |> String.capitalize

  @spec template_for_tab(String.t) :: String.t
  @doc "Returns the template to be rendered for the given tab"
  def template_for_tab("schedule"), do: "_schedule.html"
  def template_for_tab(_tab), do: "_info.html"

  @spec tab_selected?(tab :: String.t, current_tab :: String.t | nil) :: boolean()
  @doc """
  Given a station tab, and the selected tab, returns whether or not the station tab should be rendered as selected.
  """
  def tab_selected?(tab, tab), do: true
  def tab_selected?("schedule", nil), do: true
  def tab_selected?(_, _), do: false

  @spec schedule_template(Route.route_type) :: String.t
  @doc "Returns the template to render schedules for the given mode."
  def schedule_template(:commuter_rail), do: "_commuter_schedule.html"
  def schedule_template(_), do: "_mode_schedule.html"

  @spec has_alerts?([Alerts.Alert.t], Date.t, Alerts.InformedEntity.t) :: boolean
  @doc "Returns true if the given route has alerts."
  def has_alerts?(alerts, date, informed_entity) do
    alerts
    |> Enum.reject(&Alerts.Alert.is_notice?(&1, date))
    |> Alerts.Match.match(informed_entity)
    |> Enum.empty?
    |> Kernel.not
  end

  @spec station_schedule_empty_msg(atom) :: Phoenix.HTML.Safe.t
  def station_schedule_empty_msg(mode) do
    content_tag :div, class: "station-schedules-empty station-route-row" do
      [
        "There are no upcoming ",
        mode |> mode_name() |> String.downcase,
        " departures until the start of the next day's service."
      ]
    end
  end

  @spec time_differences([PredictedSchedule.t], DateTime.t) :: [Phoenix.HTML.Safe.t]
  @doc "A list of time differences for the predicted schedules, with the empty ones removed."
  def time_differences(predicted_schedules, date_time) do
    predicted_schedules
    |> Enum.reject(& &1.prediction == nil && &1.schedule == nil)
    |> Enum.sort_by(&PredictedSchedule.sort_with_status/1)
    |> Enum.take(3)
    |> Enum.flat_map(fn departure ->
      case PredictedSchedule.Display.time_difference(departure, date_time) do
        "" -> []
        difference -> [difference]
      end
    end)
  end

  @doc "URL for the embedded Google map image for the stop."
  @spec map_url(Stop.t, non_neg_integer, non_neg_integer, non_neg_integer) :: String.t
  def map_url(stop, width, height, scale) do
    opts = [
      channel: "beta_mbta_station_info",
      zoom: 16,
      scale: scale
    ] |> Keyword.merge(center_query(stop))

    GoogleMaps.static_map_url(width, height, opts)
  end

  @doc """
  Returns a map of query params to determine the center of the Google map image. If the stop is a station,
  it will have and icon in google maps and does not require a marker. Otherwise, the stop requires a marker.
  """
  @spec center_query(Stop.t) :: [markers: String.t] | [center: String.t]
  def center_query(stop) do
    if stop.station? do
      [center: location(stop)]
    else
      [markers: location(stop)]
    end
  end

  @spec clean_city(String.t) :: String.t
  defp clean_city(city) do
    city = city |> String.split("/") |> List.first
    "#{city}, MA"
  end

  @doc "Returns the url for a map showing directions from a stop to a retail location."
  @spec retail_location_directions_link(Location.t, Stop.t) :: Phoenix.HTML.Safe.t
  def retail_location_directions_link(%Location{latitude: retail_lat, longitude: retail_lng}, %Stop{latitude: stop_lat, longitude: stop_lng}) do
    href = GoogleMaps.direction_map_url({stop_lat, stop_lng}, {retail_lat, retail_lng})
    content_tag :a, ["View on map ", fa("arrow-right")], href: href, class: "no-wrap"
  end

  @doc "Creates the name to be used for station info tab"
  @spec info_tab_name([Routes.Group.t]) :: String.t
  def info_tab_name([bus: _]) do
    "Stop Info"
  end
  def info_tab_name(_) do
    "Station Info"
  end

  @doc "returns small icons for features in given DetailedStop"
  @spec feature_icons(DetailedStop.t) :: Phoenix.HTML.Safe.t
  def feature_icons(%DetailedStop{features: features}) do
    for feature <- features do
      stop_feature_icon(feature, "icon-small")
    end
  end

  @doc """
  Returns correct svg Icon for the given feature
  """
  @spec stop_feature_icon(Stops.Repo.stop_feature, String.t) :: Phoenix.HTML.Safe.t
  def stop_feature_icon(feature, class \\ "")
  def stop_feature_icon(feature, class) when feature in [:"Green-B", :"Green-C", :"Green-D", :"Green-E"] do
    icon_opts = [icon_class: class, transform: "translate(1,1)"]
    content_tag :span, class: "green-line route-branch-stop-list stop-feature-green" do
      Site.ScheduleV2View.StopList.stop_bubble_icon(:stop, Atom.to_string(feature), icon_opts)
    end
  end
  def stop_feature_icon(:parking_lot, class) do
    svg_icon(%SvgIcon{icon: :parking_lot, class: class})
  end
  def stop_feature_icon(feature, class) do
    svg_icon_with_circle(%SvgIconWithCircle{icon: feature, class: class})
  end
end
