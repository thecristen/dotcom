defmodule Site.TripPlanView do
  use Site.Web, :view
  alias Site.TripPlan.{Query, ItineraryRow}
  alias Routes.Route

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
  defp do_render_location_error(conn, field, {:too_many_results, results}) do
    render "_error_too_many_results.html", conn: conn, field: field, results: results
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

  def intermediate_bubble_params(%ItineraryRow{route: %Route{}}, bubble_params),
    do: bubble_params
  def intermediate_bubble_params(_, bubble_params) do
    %{bubble_params | bubbles: [{nil, :line}], line_only?: true}
  end

  @spec itinerary_steps_with_classes(ItineraryRow.t) :: [{String.t, String.t}]
  def itinerary_steps_with_classes(row) do
    if collapsable_row?(row) do
      do_itinerary_steps_with_classes(row)
    else
      Enum.map(row.steps, fn step -> {step, ""} end)
    end
  end

  defp do_itinerary_steps_with_classes(%ItineraryRow{steps: steps}) do
    initial_length = Enum.count(steps)
    steps
    |> Enum.with_index
    |> Enum.map(fn {step, index} ->
      cond do
        index == 0 -> {step, "data-before-reveal-button"}
        is_middle_step?(index, initial_length) -> {step, "data-hidden-step"}
        true -> {step, ""}
      end
    end)
  end

  defp is_middle_step?(index, length) do
    index >= 1 && index < length - 2
  end

  @spec collapsable_row?(ItineraryRow.t) :: boolean()
  def collapsable_row?(row) do
    length(row.steps) >= 6 && mode_class(row) != "personal"
  end
end
