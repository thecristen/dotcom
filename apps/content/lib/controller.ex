defmodule Content.Controller do
  use Phoenix.Controller
  import Plug.Conn

  def static_file(conn, _params) do
    full_url = Content.Config.url(conn.request_path)
    with {:ok, response} <- HTTPoison.get(full_url),
         %{status_code: 200} <- response do
      forward_response(conn, response)
    else
      _ -> conn
      |> halt
      |> resp(:not_found, "")
    end
  end

  def show(conn, _params) do
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
    |> resp(:ok, body)
  end
end
