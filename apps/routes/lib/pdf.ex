defmodule Routes.Pdf do
  alias Routes.Route
  alias Routes.Pdf.Helpers

  @type dated_string :: {Date.t, String.t}
  @filename "priv/pdfs.csv"
  @external_resource @filename

  @routes_to_pdfs @filename
    |> File.stream!
    |> CSV.decode

  @custom_pdfs [
    # lines to show it on, text to show, link to pdf
    {
      ["CR-Providence", "CR-Franklin", "CR-Needham", "CR-Worcester"],
      ["Back Bay to South Station schedule"],
      "/sites/default/files/route_pdfs/southstation_backbay.pdf"
    },
  ]

  @doc """

  Returns a list of PDF URLs, along with the date that the schedule starts
  being valid.  The provided date is used to filter out PDFs which are no
  longer valid.

  """
  @spec dated_urls(Routes.Route.id_t, Date.t) :: [dated_string]
  def dated_urls(route_id, date) do
    route_id
    |> do_dated_urls
    |> current_and_upcoming(date)
  end

  for {route_id, rows} <- Enum.group_by(@routes_to_pdfs, &hd/1) do
    parsed = Enum.map(rows, &Helpers.parse_date/1)
    defp do_dated_urls(unquote(route_id)), do: unquote(Macro.escape(parsed))
  end
  defp do_dated_urls(_route_id), do: []

  @spec current_and_upcoming([dated_string], Date.t) :: [dated_string]
  defp current_and_upcoming(dated_urls, date) do
    {before, aft} = Enum.split_with(dated_urls, &Date.compare(elem(&1, 0), date) != :gt)
    [List.last(before), List.first(aft)] |> Enum.filter(& &1)
  end

  @doc """
  Returns a list of {text, path}
  """
  @spec all_pdfs_for_route(Route.t, Date.t) :: [{[String.t], String.t}]
  def all_pdfs_for_route(route, date) do
    dated_pdfs_for_route(route, date) ++ custom_pdfs_for_route(route)
  end

  @spec dated_pdfs_for_route(Route.t, Date.t) :: [{[String.t], String.t}]
  defp dated_pdfs_for_route(route, date) do
    route_name = pretty_route_name(route)
    case dated_urls(route.id, date) do
      [] ->
        []
      [{_previous_date, previous_path}] ->
        [
          {[route_name, " paper schedule"], previous_path}
        ]
      [{_previous_date, previous_path}, {next_date, next_path} | _] ->
        [
          {[route_name, " paper schedule"], previous_path},
          {["upcoming schedule — effective ", Timex.format!(next_date, "{Mshort} {D}")], next_path}
        ]
    end
  end

  @spec pretty_route_name(Route.t) :: String.t | [String.t]
  defp pretty_route_name(route) do
    route_prefix = if route.type == 3, do: "Route ", else: ""
    route_name = route.name
    |> String.replace_trailing(" Line", " line")
    |> String.replace_trailing(" Ferry", " ferry")
    |> String.replace_trailing(" Trolley", " trolley")
    route_prefix <> route_name
  end

  @spec custom_pdfs_for_route(Route.t) :: [{[String.t], String.t}]
  defp custom_pdfs_for_route(route) do
    for {routes, text, link} <- @custom_pdfs, Enum.member?(routes, route.id) do
      {text, link}
    end
  end
end
