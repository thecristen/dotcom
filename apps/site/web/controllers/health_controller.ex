defmodule Site.HealthController do
  @moduledoc """
  Simple controller to return 200 OK when the website is healthy.
  """
  use Site.Web, :controller

  def index(conn, _params) do
    conn
    |> send_resp(200, "")
  end
end
