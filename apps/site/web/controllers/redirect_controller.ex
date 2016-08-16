defmodule Site.RedirectController do
  use Site.Web, :controller

  def show(conn, %{"path" => redirect}) do
    render(conn, "show.html", redirect: redirect, mobile_enabled: mobile_enabled(redirect))
  end

  defp mobile_enabled("rider_tools/t_alerts/"), do: false
  defp mobile_enabled(_), do: true
end
