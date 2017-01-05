defmodule Content.Router do
  @moduledoc """

  A Router to use for handling content coming from our CMS.
  """
  use Plug.Router

  plug :match
  plug :dispatch

  @valid_resp_headers [
    "content-type",
    "date",
    "etag",
    "expires",
    "last-modified",
    "cache-control"
  ]

  get "/sites/*_path" do
    full_url = Content.Config.url(conn.request_path)
    forward_response(conn, HTTPoison.get(full_url))
  end

  get "/*_path" do
    maybe_page = Content.Repo.page(conn.request_path, conn.query_params)
    Content.Config.apply(:page, [conn, maybe_page])
  end

  # handle all types of request
  match "/*_path" do
    error = {:error, "page not found"}
    Content.Config.apply(:page, [conn, error])
  end

  @doc """

  Responsible for forwarding an HTTPoison response back to the client.  If there's a problem with the response, returns a 404 Not Found.

  This also returns some (but not all) headers back to the client.  Headers
  like ETag and Last-Modified should help with caching.

  """
  @spec forward_response(Plug.Conn.t, {:ok, HTTPoison.Response.t} | any) :: Plug.Conn.t
  def forward_response(conn, {:ok, %{status_code: 200, body: body, headers: headers}}) do
    headers
    |> Enum.reduce(conn, fn {key, value}, conn ->
      if String.downcase(key) in @valid_resp_headers do
        put_resp_header(conn, String.downcase(key), value)
      else
        conn
      end
    end)
    |> halt
    |> send_resp(:ok, body)
  end
  def forward_response(conn, _) do
    send_resp(conn, :not_found, "")
  end
end
