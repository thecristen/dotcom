defmodule Site.RedirectController do
  use Site.Web, :controller

  def show(conn, %{"path" => redirect_parts} = params) do
    # redirect_parts is a list of URL parts which should be separated by
    # slashes.  Anything else in params is a query parameter.
    full_path = get_path(redirect_parts, params)

    # if the link is not coming from turbolinks, pass a body attribute to disable turbolinks
    turbolinks_body_attr = if Turbolinks.enabled?(conn), do: nil, else: "data-turbolinks=\"false\""

    conn
    |> put_resp_header("refresh", "5;url=" <> full_path)
    |> assign(:turbolinks_body_attr, turbolinks_body_attr)
    |> render("show.html", redirect: full_path)
  end

  @spec append_query_params(String.t, map()) :: String.t
  defp append_query_params(path, params) when params == %{}, do: path
  defp append_query_params(path, params), do: path <> "?" <> URI.encode_query(params)

  @spec get_path([String.t], map()) :: String.t
  defp get_path([], _params), do: "http://www.mbta.com/"
  defp get_path(["pass_program" | parts], params), do: "https://passprogram.mbta.com/#{parts_to_path(parts, params)}"
  defp get_path(["commerce" | parts], params), do: "https://commerce.mbta.com/#{parts_to_path(parts, params)}"
  defp get_path(parts, params), do: "http://www.mbta.com/#{parts_to_path(parts, params)}"

  @spec parts_to_path([String.t], map()) :: String.t
  defp parts_to_path(parts, params) do
    path = parts |> Enum.join("/")
    query_params = params |> Map.delete("path")
    append_query_params(path, query_params)
  end
end
