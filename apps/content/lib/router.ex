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
    with {:ok, response} <- HTTPoison.get(full_url),
         %{status_code: 200} <- response do
      forward_response(conn, response)
    else
      _ -> send_resp(conn, :not_found, "")
    end
  end

  get "/*_path" do
    maybe_page = Content.Repo.page(conn.request_path)
    {module, fun, args} = Application.get_env(:content, :page_mfa)
    apply(module, fun, args ++ [conn, maybe_page])
  end

  defp forward_response(conn, %{body: body, headers: headers}) do
    headers
    |> Enum.reduce(conn, fn {key, value}, conn ->
      if String.downcase(key) in @valid_resp_headers do
        put_resp_header(conn, header_case(key), value)
      else
        conn
      end
    end)
    |> halt
    |> send_resp(:ok, body)
  end

  defp header_case(header) do
    header
    |> String.split("-")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join("-")
  end
end
