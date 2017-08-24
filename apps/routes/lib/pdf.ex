defmodule Routes.Pdf do
  alias Routes.Route
  alias Routes.Pdf.Helpers

  @type dated_string :: {Date.t, String.t}
  @filename "priv/pdfs.csv"
  @external_resource @filename

  @routes_to_pdfs @filename
    |> File.stream!
    |> CSV.decode

  @doc "Returns a URL for a PDF of the given schedule."
  @spec url(Route.t) :: String.t | nil
  def url(%Route{id: route_id}) do
    case do_dated_urls(route_id) do
      [{_, url} | _] -> url
      _ -> nil
    end
  end

  @doc """

  Returns a list of PDF URLs, along with the date that the schedule starts
  being valid.  The provided date is used to filter out PDFs which are no
  longer valid.

  """
  @spec dated_urls(Route.t, Date.t) :: [dated_string]
  def dated_urls(%Route{id: route_id}, date) do
    route_id
    |> do_dated_urls
    |> filter_outdated(date)
  end

  for {route_id, rows} <- Enum.group_by(@routes_to_pdfs, &hd/1) do
    parsed = Enum.map(rows, &Helpers.parse_date/1)
    defp do_dated_urls(unquote(route_id)), do: unquote(Macro.escape(parsed))
  end
  defp do_dated_urls(_route_id), do: []

  @doc """
  Returns either:
    1) [currently active schedule pdf, next upcoming schedule pdf] when there are both a current
       and a next pdf
    2) [currently active scheudle pdf] when there is only a current pdf
  """
  @spec filter_outdated([dated_string], Date.t) :: [dated_string]
  def filter_outdated(dated_urls, date) do
    {before, aft} = Enum.split_with(dated_urls, &Date.compare(elem(&1, 0), date) != :gt)
    [do_filter_outdated(before, :before), do_filter_outdated(aft, :after)] |> Enum.filter(& &1)
  end

  def do_filter_outdated([], _), do: nil
  def do_filter_outdated(before, :before), do: List.last(before)
  def do_filter_outdated([aft | _rest], :after), do: aft

  def south_station_back_bay_pdf(route) do
    south_station_commuter_rail_lines = ["CR-Kingston", "CR-Middleborough", "CR-Providence", "CR-Fairmount",
                                         "CR-Franklin", "CR-Needham", "CR-Greenbush", "CR-Worcester"]
    if route.id in south_station_commuter_rail_lines do
      "http://old.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Commuter_Rail/southstation_backbay.pdf"
    else
      nil
    end
  end
end
