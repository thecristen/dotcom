defmodule Site.Plug.Mticket do

  @moduledoc """

  A module Plug to detect requests coming from the old mTicket app and send a different HTML response
  with a simlple page containing a notification.

  This plug is only called from the mode and schedule controllers because only two routes are currently
  being proxied by mTicket.

  There is no attempt to automatically redirect the user because these endpoints are called when
  mTicket loads, not when the Schedules or Alerts button is clicked in the app.

  """

  @behaviour Plug

  use Site.Web, :controller
  import Plug.Conn

  def init(_opts), do: []

  def call(conn, _opts) do
    # this is the user agent that mTrip 1.0 uses to proxy some pages when the app is first loaded
    #if get_req_header(conn, "user-agent") == ["Java/1.8.0_91"] do
    if true do
      content_description = if String.contains?(conn.request_path, "schedule"), do: "schedules", else: "alerts"
      full_link_path = String.replace("#{Site.Endpoint.url}#{conn.request_path}", "http://", "https://")
      conn
      |> put_layout(false)
      |> render(Site.MticketView, "notice.html", full_link_path: full_link_path, content_description: content_description)
      |> halt
    else
      conn
    end
  end
end
