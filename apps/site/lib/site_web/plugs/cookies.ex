defmodule SiteWeb.Plugs.Cookies do
  @moduledoc """
  A module Plug that creates a cookie with a unique ID if this cookie does not already exist.
  """

  @behaviour Plug
  @cookie_name "mbta_id"

  @impl true
  def init([]), do: []

  @impl true
  def call(%{cookies: %{@cookie_name => _mbta_id}} = conn, _) do
    conn
  end
  def call(conn, _) do
    Plug.Conn.put_resp_cookie(conn, @cookie_name, unique_id(), cookie_options())
  end

  defp twenty_years_from_now, do: 20 * 365 * 24 * 60 * 60

  defp cookie_options, do: [http_only: false, max_age: twenty_years_from_now()]

  defp unique_id, do: to_string(:erlang.phash2({node(), System.unique_integer()}))
end
