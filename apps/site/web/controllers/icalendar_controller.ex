defmodule Site.IcalendarController do
  use Site.Web, :controller
  alias Site.IcalendarGenerator

  def show(conn, %{"event_id" => id}) do
    event = Content.Repo.event!(id)

    conn
    |> put_resp_content_type("text/calendar")
    |> put_resp_header("content-disposition", "attachment; filename='#{filename(event.title)}.ics'")
    |> send_resp(200, IcalendarGenerator.to_ical(event))
  end

  defp filename(title) do
    title
    |> Phoenix.HTML.safe_to_string()
    |> String.downcase
    |> String.replace(" ", "_")
    |> decode_ampersand_html_entity
  end

  defp decode_ampersand_html_entity(string) do
    String.replace(string, "&amp;", "&")
  end
end
