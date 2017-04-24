defmodule Routes.Pdf.Helpers do
  @doc "Parses a CSV row into a tuple of {date, pdf_url}"
  @spec parse_date([String.t]) :: {Date.t, String.t}
  def parse_date([_route_id, pdf_url, date_str]) do
    {:ok, date} = Date.from_iso8601(date_str)
    {date, pdf_url}
  end
end
