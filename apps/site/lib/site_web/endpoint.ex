defmodule SiteWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :site

  socket "/socket", SiteWeb.UserSocket

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug SiteWeb.Plugs.Static

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug SiteWeb.Plugs.RemoteIp
  plug Plug.RequestId
  plug Logster.Plugs.Logger, formatter: Site.Logster.SafeStringFormatter

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_site_key",
    signing_salt: "TInvb4GN"

  plug SiteWeb.Router
end
