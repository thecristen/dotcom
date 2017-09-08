defmodule Site.TripPlanView do
  use Site.Web, :view
  require Routes.Route
  alias Site.TripPlan.{Query, ItineraryRow}
  alias Routes.Route
  @meters_per_mile 1609.34

  @spec itinerary_explanation(Query.t) :: iodata
  def itinerary_explanation(%Query{time: :unknown}) do
    []
  end
  def itinerary_explanation(%Query{} = q) do
    [
      trip_explanation(q),
      " shown are based on the fastest route and closest ",
      time_explanation(q),
      " to ",
      dt_explanation(q),
      "."
    ]
  end

  defp trip_explanation(%{wheelchair_accessible?: false}) do
    "Trips"
  end
  defp trip_explanation(%{wheelchair_accessible?: true}) do
    "Wheelchair accessible trips"
  end

  defp time_explanation(%{time: {:arrive_by, _dt}}) do
    "arrival"
  end
  defp time_explanation(%{time: {:depart_at, _dt}}) do
    "departure"
  end

  defp dt_explanation(%{time: {_type, dt}}) do
    [
      Timex.format!(dt, "{h12}:{m} {AM}, {WDfull}, {Mfull} "),
      Inflex.ordinalize(dt.day)
    ]
  end

  @spec rendered_location_error(Plug.Conn.t, Query.t | nil, :from | :to) :: Phoenix.HTML.Safe.t
  def rendered_location_error(conn, query_or_nil, location_field)
  def rendered_location_error(_conn, nil, _location_field) do
    ""
  end
  def rendered_location_error(%Plug.Conn{} = conn, %Query{} = query, field) when field in [:from, :to] do
    case Map.get(query, field) do
      {:error, error} ->
        do_render_location_error(conn, field, error)
      _ ->
        ""
    end
  end

  @spec do_render_location_error(Plug.Conn.t, :from | :to, TripPlan.Geocode.error) :: Phoenix.HTML.Safe.t
  defp do_render_location_error(_conn, _field, :no_results) do
    "That address was not found. Please try a different address."
  end
  defp do_render_location_error(conn, field, {:multiple_results, results}) do
    render "_error_multiple_results.html", conn: conn, field: field, results: results
  end
  defp do_render_location_error(_conn, _field, :required) do
    "This field is required."
  end
  defp do_render_location_error(_conn, _field, :unknown) do
    "An unknown error occurred. Please try again, or try a different address."
  end

  @spec rendered_plan_error(term) :: Phoenix.HTML.Safe.t
  def rendered_plan_error(:prereq) do
    ""
  end
  def rendered_plan_error(no_plan) when no_plan in [:path_not_found, :too_close] do
    "We were unable to plan a trip between those locations."
  end
  def rendered_plan_error(:outside_bounds) do
    "We can only plan trips inside the MBTA transitshed."
  end
  def rendered_plan_error(:no_transit_times) do
    "We were unable to plan a trip at the time you selected."
  end
  def rendered_plan_error(:location_not_accessible) do
    "We were unable to plan an accessible trip between those locations."
  end
  def rendered_plan_error(_) do
    "We were unable to plan your trip. Please try again later."
  end

  def location_input_class(params, key) do
    if Query.fetch_lat_lng(params, Atom.to_string(key)) == :error do
      ""
    else
      "trip-plan-current-location"
    end
  end

  def mode_class(%ItineraryRow{route: %Route{} = route}) do
    route
    |> Site.Components.Icons.SvgIcon.get_icon_atom
    |> hyphenated_mode_string
  end
  def mode_class(_), do: "personal"

  @spec stop_departure_display(ItineraryRow.t) :: {:render, String.t} | :blank
  def stop_departure_display(itinerary_row) do
    if itinerary_row.trip do
      :blank
    else
      {:render, format_schedule_time(itinerary_row.departure)}
    end
  end

  @spec render_stop_departure_display(:blank | {:render, String.t}) :: Phoenix.HTML.Safe.t
  def render_stop_departure_display(:blank), do: nil
  def render_stop_departure_display({:render, formatted_time}) do
    content_tag :div, formatted_time, class: "pull-right"
  end

  def bubble_params(%ItineraryRow{transit?: true} = itinerary_row, _row_idx) do
    base_params = %Site.StopBubble.Params{
      route_id: ItineraryRow.route_id(itinerary_row),
      route_type: ItineraryRow.route_type(itinerary_row),
      render_type: :stop,
      bubble_branch: ItineraryRow.route_name(itinerary_row)
    }
    first_step_class = if Enum.count(itinerary_row.steps) >= 4, do: ["stop dotted"], else: ["stop"]

    params =
      itinerary_row.steps
      |> Enum.zip(Stream.concat(first_step_class, Stream.repeatedly(fn -> "stop"  end)))
      |> Enum.map(fn {step, class} ->
        {step, [%{base_params | class: class}]}
      end)

    [{:transfer, [%{base_params | class: "stop"}]} | params]
  end
  def bubble_params(%ItineraryRow{transit?: false} = itinerary_row, row_idx) do
    params =
      itinerary_row.steps
      |> Enum.map(fn step ->
        {step,
          [%Site.StopBubble.Params{
            render_type: :empty,
            class: "line dotted",
          }]}
      end)

    transfer_bubble_type =
      if row_idx == 0 do
        :terminus
      else
        :stop
      end

    [{:transfer,
          [%Site.StopBubble.Params{
            render_type: transfer_bubble_type,
            class: "#{transfer_bubble_type} dotted",
          }]}
     | params]
  end

  def render_steps(steps, mode_class) do
    for {step, bubbles} <- steps do
      render "_itinerary_row_step.html",
        step: step,
        mode_class: mode_class,
        bubble_params: bubbles
    end
  end

  @spec display_meters_as_miles(float) :: String.t
  def display_meters_as_miles(meters) do
    Float.to_string(meters / @meters_per_mile, decimals: 1)
  end

  def format_additional_route(%Route{id: "Green" <> _branch} = route, direction_id) do
    [
      format_green_line_name(route.name),
      " ",
      direction(direction_id, route),
      " towards ",
      GreenLine.naive_headsign(route.id, direction_id)
    ]
  end

  defp format_green_line_name("Green Line " <> branch), do: "Green Line (#{branch})"

  @spec icon_for_route(Route.t) :: Phoenix.HTML.Safe.t
  def icon_for_route(route) do
    svg_icon_with_circle(%SvgIconWithCircle{icon: route})
  end

  def datetime_from_query(%Query{time: {_, datetime}}), do: datetime
  def datetime_from_query(nil), do: Util.now()

  def trip_plan_datetime_select(conn, form, query) do
    query
    |> datetime_from_query()
    |> do_trip_plan_datetime_select(conn, form)
  end

  defp do_trip_plan_datetime_select(datetime, conn, form) do
    lab_enabled? = Laboratory.enabled?(conn, :js_datepicker)
    time_options = [
      hour: [selected: datetime.hour],
      minute: [selected: datetime.minute],
      default: datetime
    ]
    date_options = [
      year: [options: Range.new(datetime.year, datetime.year + 1), selected: datetime.year],
      month: [selected: datetime.month],
      day: [selected: datetime.day],
      default: datetime
    ]
    content_tag(:div, [
      custom_time_select(form, datetime, time_options, lab_enabled?),
      " on ",
      custom_date_select(form, datetime, date_options, lab_enabled?)
    ], class: "form-group plan-date-time")
  end

  def custom_date_select(form, datetime, options, true) do
    # the accessible-date-picker uses the label's offset to determine where to position the calendar
    # when toggling it, and throws an error if the label is omitted. So if we don't want to show a label,
    # we can't just set display:none because that messes up the offset. That's why the label has no text
    # and is set to aria-hidden="true".
    content_tag(:div, [
      content_tag(:button, Timex.format!(datetime, "{WDfull}, {Mfull} {D}, {YYYY}"), id: "plan-date-link", class: "plan-date-link plan-datetime-link", type: "button"),
      content_tag(:label, [], for: "plan-date-input", name: "Date", aria: [hidden: true]),
      content_tag(:input, [], type: "text", class: "plan-date-input", id: "plan-date-input", aria: [hidden: true]),
      date_select(form, :date_time, Keyword.put(options, :builder, &custom_date_select_builder/1))
    ], class: "plan-date", id: "plan-date")
  end

  def custom_date_select(form, _datetime, options, false) do
    content_tag(:div, date_select(form, :date_time, options), class: "plan-date", id: "plan-date")
  end

  def custom_date_select_builder(field) do
    content_tag(:div, [
      field.(:month, []),
      field.(:day, []),
      field.(:year, [])
    ], class: "plan-date-select hidden-js", id: "plan-date-select")
  end

  def custom_time_select(form, datetime, options, true) do
    content_tag(:div, [
      content_tag(:button, Timex.format!(datetime, "{h12}:{m} {AM}"), id: "plan-time-link", class: "plan-time-link plan-datetime-link", type: "button"),
      time_select(form, :date_time, Keyword.put(options, :builder, &custom_time_select_builder/1))
    ], class: "plan-time", id: "plan-time")
  end

  def custom_time_select(form, _datetime, options, false) do
    content_tag(:div, time_select(form, :date_time, options), class: "plan-time", id: "plan-time")
  end

  defp custom_time_select_builder(field) do
    content_tag(:div, [
      field.(:hour, []),
      ":",
      field.(:minute, [])
    ], class: "plan-time-select hidden-js", id: "plan-time-select")
  end
end
