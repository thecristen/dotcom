defmodule Site.StaticFileController do
  use Site.Web, :controller

  @config Application.get_env(:site, StaticFileController)
  @response_fn @config[:response_fn]

  def index(conn, _params) do
    {m, f} = @response_fn
    apply(m, f, [conn])
  end

  def send_file(conn) do
    full_url = Content.Config.url(conn.request_path)
    forward_static_file(conn, full_url)
  end

  def forward_through_cdn(conn) do
    url = static_url(Site.Endpoint, conn.request_path)
    redirect(conn, external: url)
  end
end
