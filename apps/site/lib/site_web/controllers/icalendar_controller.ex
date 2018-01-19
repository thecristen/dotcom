defmodule SiteWeb.IcalendarController do
  use SiteWeb, :controller
  alias Site.IcalendarGenerator

  def show(conn, %{"event_id" => id}) do
    case Content.Repo.event(Content.Helpers.int_or_string_to_int(id)) do
      :not_found -> render_404(conn)
      event ->
        conn
        |> put_resp_content_type("text/calendar")
        |> put_resp_header("content-disposition", "attachment; filename='#{filename(event.title)}.ics'")
        |> send_resp(200, IcalendarGenerator.to_ical(event))
    end
  end

  defp filename(title) do
    title
    |> String.downcase
    |> String.replace(" ", "_")
    |> decode_ampersand_html_entity
  end

  defp decode_ampersand_html_entity(string) do
    String.replace(string, "&amp;", "&")
  end
end
