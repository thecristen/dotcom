defmodule SiteWeb.IcalendarController do
  use SiteWeb, :controller
  alias Site.IcalendarGenerator

  def show(conn, %{"event_id" => _} = params) do
    full_path = String.replace(conn.request_path, "/icalendar", "")
    event = params
            |> best_cms_path(full_path)
            |> Content.Repo.get_page(conn.query_params)
    case event do
      %Content.Event{} = event ->
        conn
        |> put_resp_content_type("text/calendar")
        |> put_resp_header("content-disposition", "attachment; filename='#{filename(event.title)}.ics'")
        |> send_resp(200, IcalendarGenerator.to_ical(event))
      _ -> render_404(conn)
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
