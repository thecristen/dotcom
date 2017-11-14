defmodule SiteWeb.EventView do
  use SiteWeb, :view
  import Site.FontAwesomeHelpers
  import SiteWeb.ContentView, only: [file_description: 1, render_duration: 2]
  import SiteWeb.ContentHelpers, only: [content: 1]

  @spec shift_date_range(String.t, integer) :: String.t
  def shift_date_range(iso_string, shift_value) do
    iso_string
    |> Timex.parse!("{ISOdate}")
    |> Timex.shift(months: shift_value)
    |> Timex.beginning_of_month
    |> Timex.format!("{ISOdate}")
  end

  @spec calendar_title(String.t) :: String.t
  def calendar_title(month), do: name_of_month(month)

  @spec no_results_message(String.t) :: String.t
  def no_results_message(month) do
    "Sorry, there are no events in #{name_of_month(month)}."
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
