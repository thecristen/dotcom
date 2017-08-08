defmodule Site.EventView do
  use Site.Web, :view
  import Site.FontAwesomeHelpers
  import Site.ContentView, only: [file_description: 1, render_duration: 2]
  import Site.ContentHelpers, only: [content: 1]

  @spec shift_date_range(String.t, integer) :: String.t
  def shift_date_range(iso_string, shift_value) do
    iso_string
    |> Timex.parse!("{ISOdate}")
    |> Timex.shift(months: shift_value)
    |> Timex.beginning_of_month
    |> Timex.format!("{ISOdate}")
  end

  @spec calendar_title(%{required(String.t) => String.t}) :: String.t
  def calendar_title(%{"month" => month}) do
    if valid_iso_month?(month) do
      name_of_month(month)
    else
      calendar_title(%{})
    end
  end
  def calendar_title(_missing_month) do
    "Upcoming Events"
  end

  @spec no_results_message(%{required(String.t) => String.t}) :: String.t
  def no_results_message(%{"month" => month}) do
    if valid_iso_month?(month) do
      "Sorry, there are no events in #{name_of_month(month)}."
    else
      no_results_message(%{})
    end
  end
  def no_results_message(_missing_month) do
    "Sorry, there are no upcoming events."
  end

  defp valid_iso_month?(iso_string) do
    {:ok, _date}
    |> match?(Timex.parse(iso_string, "{ISOdate}"))
  end

  defp name_of_month(iso_string) do
    iso_string
    |> Timex.parse!("{ISOdate}")
    |> Timex.format!("{Mfull}")
  end

  @doc "Returns a pretty format for the event's city and state"
  @spec city_and_state(%Content.Event{}) :: String.t | nil
  def city_and_state(%Content.Event{city: city, state: state}) do
    if city && state do
      "#{city}, #{state}"
    end
  end
end
