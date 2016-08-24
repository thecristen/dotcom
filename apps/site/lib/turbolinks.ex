defmodule Turbolinks do
  import Plug.Conn, only: [get_req_header: 2]
  alias Phoenix.HTML.Tag

  def enabled?(conn) do
    case get_req_header(conn, "turbolinks-referrer") do
      [] -> false
      _ -> true
    end
  end

  def turbolinks_cache(%{private: %{phoenix_view: Site.CustomerSupportView}}) do
    Tag.tag :meta, name: "turbolinks-cache-control", content: "no-cache"
  end
  def turbolinks_cache(_conn) do
    ""
  end
end

defmodule Turbolinks.Plug do
  @moduledoc """

  Handles notifying Turbolinks of an redirect.

  See https://github.com/turbolinks/turbolinks#following-redirects for more
  information.

  """

  import Phoenix.Controller, only: [get_flash: 2,
                                    put_flash: 3]

  import Plug.Conn, only: [register_before_send: 2,
                           get_resp_header: 2,
                           put_resp_header: 3]

  def init([]), do: []

  def call(conn, []) do
    if Turbolinks.enabled?(conn) do
      conn
      |> check_flash
      |> register_before_send(&before_send/1)
    else
      conn
    end
  end

  def check_flash(conn) do
    case get_flash(conn, :turbolinks_redirect) do
      nil -> conn
      location -> conn |> put_resp_header("turbolinks-location", location)
    end
  end

  def before_send(%{status: status} = conn) when status >= 300 and status < 400 do
    location = conn
    |> get_resp_header("location")
    |> List.first

    conn
    |> put_flash(:turbolinks_redirect, location)
  end
  def before_send(conn) do
    conn
  end
end
