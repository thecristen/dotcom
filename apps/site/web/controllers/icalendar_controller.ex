defmodule Site.IcalendarController do
  use Site.Web, :controller
  alias Site.IcalendarGenerator

  def show(conn, %{"event_id" => id}) do
    event = Content.Repo.event!(id)

    conn
    |> put_resp_content_type("text/calendar")
    |> put_resp_header("content-disposition", "attachment; filename='#{filename(event)}.ics'")
    |> send_resp(200, IcalendarGenerator.to_ical(event))
  end

  defp filename(event) do
    event.title
    |> String.downcase
    |> String.replace(" ", "_")
  end
end
