defmodule SiteWeb.TripPlanView do
  use SiteWeb, :view
  require Routes.Route
  alias Site.TripPlan.{Query, ItineraryRow}
  alias Routes.Route
  alias Phoenix.HTML.Form
  alias SiteWeb.PartialView.SvgIconWithCircle
  @meters_per_mile 1609.34

  @spec itinerary_explanation(Query.t(), map) :: iodata
  def itinerary_explanation(%Query{time: :unknown}, _) do
    []
  end

  def itinerary_explanation(%Query{} = q, modes) do
    [
      trip_explanation(q),
      " shown are based on your selections (",
      selected_modes_string(modes),
      ") and closest ",
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

  @spec selected_modes_string(map) :: String.t
  def selected_modes_string(%{subway: true, commuter_rail: true, bus: true, ferry: true}) do
    "all modes"
  end
  def selected_modes_string(%{} = modes) do
    modes
    |> Enum.filter(fn {_, selected?} -> selected? end)
    |> Enum.map(fn {key, _} -> key |> mode_name() |> String.downcase() end)
    |> Enum.join(", ")
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

  @spec rendered_location_error(Plug.Conn.t(), Query.t() | nil, :from | :to) ::
          Phoenix.HTML.Safe.t()
  def rendered_location_error(conn, query_or_nil, location_field)

  def rendered_location_error(_conn, nil, _location_field) do
    ""
  end

  def rendered_location_error(%Plug.Conn{} = conn, %Query{} = query, field)
      when field in [:from, :to] do
    case Map.get(query, field) do
      {:error, error} ->
        do_render_location_error(conn, field, error)

      _ ->
        ""
    end
  end

  @spec do_render_location_error(Plug.Conn.t(), :from | :to, TripPlan.Geocode.error()) ::
          Phoenix.HTML.Safe.t()
  defp do_render_location_error(_conn, _field, :no_results) do
    "We're sorry, but we couldn't find that address."
  end

  defp do_render_location_error(conn, field, {:multiple_results, results}) do
    render("_error_multiple_results.html", conn: conn, field: field, results: results)
  end

  defp do_render_location_error(_conn, _field, :required) do
    "This field is required."
  end

  defp do_render_location_error(_conn, _field, :unknown) do
    "An unknown error occurred. Please try again, or try a different address."
  end

  @spec rendered_plan_error(term) :: Phoenix.HTML.Safe.t()
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

  def mode_class(%ItineraryRow{route: %Route{} = route}), do: route_to_class(route)
  def mode_class(_), do: "personal-itinerary"

  @spec stop_departure_display(ItineraryRow.t()) :: {:render, String.t()} | :blank
  def stop_departure_display(itinerary_row) do
    if itinerary_row.trip do
      :blank
    else
      {:render, format_schedule_time(itinerary_row.departure)}
    end
  end

  @spec render_stop_departure_display(:blank | {:render, String.t()}) :: Phoenix.HTML.Safe.t()
  def render_stop_departure_display(:blank), do: nil

  def render_stop_departure_display({:render, formatted_time}) do
    content_tag(:div, formatted_time, class: "pull-right")
  end

  def bubble_params(%ItineraryRow{transit?: true} = itinerary_row, _row_idx) do
    base_params = %Site.StopBubble.Params{
      route_id: ItineraryRow.route_id(itinerary_row),
      route_type: ItineraryRow.route_type(itinerary_row),
      render_type: :stop,
      bubble_branch: ItineraryRow.route_name(itinerary_row)
    }

    params =
      itinerary_row.steps
      |> Enum.map(fn step ->
        {step, [base_params]}
      end)

    [{:transfer, [%{base_params | class: "stop transfer"}]} | params]
  end

  def bubble_params(%ItineraryRow{transit?: false} = itinerary_row, row_idx) do
    params =
      itinerary_row.steps
      |> Enum.map(fn step ->
        {step,
         [
           %Site.StopBubble.Params{
             render_type: :empty,
             class: "line"
           }
         ]}
      end)

    transfer_bubble_type =
      if row_idx == 0 do
        :terminus
      else
        :stop
      end

    [
      {:transfer,
       [
         %Site.StopBubble.Params{
           render_type: transfer_bubble_type,
           class: [Atom.to_string(transfer_bubble_type), " transfer"]
         }
       ]}
      | params
    ]
  end

  def render_steps(conn, steps, mode_class, itinerary_id, row_id) do
    for {step, bubbles} <- steps do
      render(
        "_itinerary_row_step.html",
        step: step.description,
        alerts: step.alerts,
        stop_id: step.stop_id,
        itinerary_idx: itinerary_id,
        row_idx: row_id,
        mode_class: mode_class,
        bubble_params: bubbles,
        conn: conn
      )
    end
  end

  @spec display_meters_as_miles(float) :: String.t()
  def display_meters_as_miles(meters) do
    :erlang.float_to_binary(meters / @meters_per_mile, decimals: 1)
  end

  def format_additional_route(%Route{id: "Green" <> _branch} = route, direction_id) do
    [
      format_green_line_name(route.name),
      " ",
      Route.direction_name(route, direction_id),
      " towards ",
      GreenLine.naive_headsign(route.id, direction_id)
    ]
  end

  defp format_green_line_name("Green Line " <> branch), do: "Green Line (#{branch})"

  @spec accessibility_icon(TripPlan.Itinerary.t()) :: Phoenix.HTML.Safe.t()
  defp accessibility_icon(%TripPlan.Itinerary{accessible?: accessible?}) do
    content_tag(
      :span,
      [
        svg_icon_with_circle(%SvgIconWithCircle{
          icon:
            if accessible? do
              :access
            else
              :no_access
            end,
          size: :small,
          show_tooltip?: false,
          aria_hidden?: true
        }),
        if accessible? do
          "Accessible"
        else
          "May not be accessible"
        end
      ],
      class: "trip-plan-itinerary-accessibility"
    )
  end

  @spec icon_for_route(Route.t()) :: Phoenix.HTML.Safe.t()
  def icon_for_route(route) do
    svg_icon_with_circle(%SvgIconWithCircle{icon: route})
  end

  def datetime_from_query(%Query{time: {_, dt}}), do: dt
  def datetime_from_query(nil), do: Util.now()

  @spec format_plan_type_for_title(Query.t()) :: Phoenix.HTML.Safe.t()
  def format_plan_type_for_title(%{time: {:arrive_by, dt}}), do: ["Arrive by ", Timex.format!(dt, "{h12}:{m} {AM}, {M}/{D}/{YYYY}")]
  def format_plan_type_for_title(%{time: {:depart_at, dt}}), do: ["Depart at ", Timex.format!(dt, "{h12}:{m} {AM}, {M}/{D}/{YYYY}")]
  def format_plan_type_for_title(nil), do: ["Depart at ", Timex.format!(Util.now(), "{h12}:{m} {AM}, {M}/{D}/{YYYY}")]

  def trip_plan_datetime_select(form, datetime) do
    time_options = [
      hour: [options: 1..12, selected: Timex.format!(datetime, "{h12}")],
      minute: [selected: datetime.minute]
    ]

    date_options = [
      year: [options: Range.new(datetime.year, datetime.year + 1), selected: datetime.year],
      month: [selected: datetime.month],
      day: [selected: datetime.day],
      default: datetime
    ]

    content_tag(
      :div,
      [
        custom_time_select(form, datetime, time_options),
        custom_date_select(form, datetime, date_options)
      ],
      class: "form-group plan-date-time"
    )
  end

  @spec custom_date_select(Form.t(), DateTime.t(), Keyword.t()) :: Phoenix.HTML.Safe.t()
  defp custom_date_select(form, datetime, options) do
    min_date = Timex.format!(Util.now(), "{0M}/{0D}/{YYYY}")
    max_date = Timex.format!(Schedules.Repo.end_of_rating(), "{0M}/{0D}/{YYYY}")
    current_date = Timex.format!(datetime, "{WDfull}, {Mfull} {D}, {YYYY}")
    aria_label = "#{current_date}, click or press the enter or space key to edit the date"

    content_tag(
      :div,
      [
        content_tag(
          :label,
          content_tag(
            :div,
            svg_icon_with_circle(%SvgIconWithCircle{icon: :calendar, show_tooltip?: false}),
            class: "m-trip-plan__calendar-input-icon",
            aria_hidden: "true"
          ),
          id: "plan-date-label",
          class: "m-trip-plan__calendar-input-label",
          for: "plan-date-input",
          name: "Date",
          aria_label: aria_label
        ),
        content_tag(
          :input,
          [],
          type: "text",
          class: "plan-date-input",
          id: "plan-date-input",
          data: ["min-date": min_date, "max-date": max_date]
        ),
        date_select(
          form,
          :date_time,
          Keyword.put(options, :builder, &custom_date_select_builder/1)
        )
      ],
      class: "plan-date",
      id: "plan-date"
    )
  end

  @spec custom_date_select_builder(fun) :: Phoenix.HTML.Safe.t()
  defp custom_date_select_builder(field) do
    content_tag(
      :div,
      [
        content_tag(:label, "Month", for: "plan_date_time_month", class: "sr-only"),
        field.(:month, class: "c-select"),
        content_tag(:label, "Day", for: "plan_date_time_day", class: "sr-only"),
        field.(:day,  class: "c-select"),
        content_tag(:label, "Year", for: "plan_date_time_year", class: "sr-only"),
        field.(:year,  class: "c-select")
      ],
      class: "plan-date-select hidden-js",
      id: "plan-date-select"
    )
  end

  @spec custom_time_select(Form.t(), DateTime.t(), Keyword.t()) :: Phoenix.HTML.Safe.t()
  defp custom_time_select(form, datetime, options) do
    current_time = Timex.format!(datetime, "{h12}:{m} {AM}")
    aria_label = "#{current_time}, click or press the enter or space key to edit the time"

    content_tag(
      :div,
      [
        content_tag(
          :label,
          [],
          id: "plan-time-label",
          class: "m-trip-plan__time-input-label",
          for: "plan-time-input",
          name: "Time",
          aria_label: aria_label
        ),
        time_select(
          form,
          :date_time,
          Keyword.put(options, :builder, &custom_time_select_builder(&1, datetime))
        )
      ],
      class: "plan-time",
      id: "plan-time"
    )
  end

  defp custom_time_select_builder(field, datetime) do
    content_tag(
      :div,
      [
        content_tag(:label, "Hour", for: "plan_date_time_hour", class: "sr-only"),
        field.(:hour, [class: "c-select"]),
        content_tag(:label, "Minute", for: "plan_date_time_minute", class: "sr-only"),
        field.(:minute, [class: "c-select"]),
        " ",
        content_tag(:label, "AM or PM", for: "plan_date_time_am_pm", class: "sr-only"),
        select(
          :date_time,
          :am_pm,
          [AM: "AM", PM: "PM"],
          selected: Timex.format!(datetime, "{AM}"),
          name: "plan[date_time][am_pm]",
          id: "plan_date_time_am_pm",
          class: "c-select plan-date-time-am-pm"
        )
      ],
      class: "plan-time-select",
      id: "plan-time-select"
    )
  end

  @spec transfer_route_name(Route.t()) :: String.t()
  def transfer_route_name(%Route{type: type} = route) when type in [0, 1] do
    route
    |> Route.to_naive()
    |> Map.get(:name)
  end

  def transfer_route_name(%Route{type: type}) do
    SiteWeb.ViewHelpers.mode_name(type)
  end
end
