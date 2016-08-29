defmodule Site.BodyClass do
  @moduledoc """

  Contains the logic for the className of the <body> element.

  If we can detect from the conn that JavaScript is enabled (via Turbolinks),
  then we can set the JS header automatically.  Additionally, we set an error
  class if we detect that we're rendering an error page.

  """
  import Plug.Conn, only: [get_req_header: 2]

  def class_name(conn) do
    [javascript_class(conn),
     error_class(conn)]
     |> Enum.filter(&(&1 != ""))
     |> Enum.join(" ")
  end

  defp javascript_class(conn) do
    case get_req_header(conn, "turbolinks-referrer") do
      [] -> "no-js"
      _ -> "js"
    end
  end

  defp error_class(%{private: %{phoenix_view: view_module}}) do
    case view_module do
      Site.ErrorView -> "not-found"
      Site.CrashView -> "not-found"
      _ -> ""
    end
  end
  defp error_class(_conn) do
    ""
  end
end
