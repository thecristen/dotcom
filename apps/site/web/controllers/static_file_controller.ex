defmodule Site.StaticFileController do
  use Site.Web, :controller

  def index(conn, _params) do
    full_url = Content.Config.url(conn.request_path)
    forward_static_file(conn, full_url)
  end
end
