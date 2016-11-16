defmodule Site.RedirectController do
  use Site.Web, :controller

  def show(conn, %{"path" => redirect_parts} = params) do
    # redirect_parts is a list of URL parts which should be separated by
    # slashes.  Anything else in params is a query parameter.
    path = redirect_parts |> Enum.join("/")
    query_params = params |> Map.delete("path")
    {subdomain, full_path} = full_path(path, query_params)

    render(conn, "show.html",
      subdomain: subdomain,
      redirect: full_path,
      mobile_enabled: mobile_enabled(full_path))
  end

  @spec full_path(String.t, map()) :: {boolean, String.t}
  defp full_path("pass_program", params) do
    {true, append_query_params("https://passprogram.mbta.com/", params)}
  end
  defp full_path(path, params) do
    {false, append_query_params(path, params) }
  end

  @spec mobile_enabled(String.t) :: boolean
  defp mobile_enabled("rider_tools/t_alerts"), do: false
  defp mobile_enabled("passprogram"), do: false
  defp mobile_enabled(_), do: true

  @spec append_query_params(String.t, map()) :: String.t
  defp append_query_params(path, params) when params == %{}, do: path
  defp append_query_params(path, params), do: path <> "?" <> URI.encode_query(params)
end
