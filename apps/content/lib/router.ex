defmodule Content.Router do
  @moduledoc """

  A Router to use for handling content coming from our CMS.
  """
  use Plug.Router

  plug :match
  plug :dispatch

  get "/sites/*_path" do
    full_url = Content.Config.url(conn.request_path)
    with {:ok, response} <- HTTPoison.get(full_url),
         %{status_code: 200} <- response do
      forward_response(conn, response)
    else
      _ -> conn
      |> halt
      |> send_resp(:not_found, "")
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
      put_resp_header(conn, key, value)
    end)
    |> halt
    |> send_resp(:ok, body)
  end
end
