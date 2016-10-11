defmodule Site.RedirectController do
  use Site.Web, :controller

  def show(conn, %{"path" => redirect_parts} = params) do
    # redirect_parts is a list of URL parts which should be separated by
    # slashes.  Anything else in params is a query parameter.
    path = redirect_parts |> Enum.join("/")
    query_params = params |> Map.delete("path")

    full_path = if query_params == %{} do
      path
    else
      path <> "?" <> URI.encode_query(query_params)
    end

    render(conn, "show.html",
      redirect: full_path,
      mobile_enabled: mobile_enabled(full_path))
  end

  defp mobile_enabled("rider_tools/t_alerts"), do: false
  defp mobile_enabled(_), do: true
end
