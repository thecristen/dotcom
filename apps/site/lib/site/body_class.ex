defmodule Site.BodyClass do
  @moduledoc """

  Contains the logic for the className of the <body> element.

  If we can detect from the conn that JavaScript is enabled (via Turbolinks),
  then we can set the JS header automatically.  Additionally, we set an error
  class if we detect that we're rendering an error page.

  """
  def class_name(conn) do
    [javascript_class(conn),
     error_class(conn)]
     |> Enum.filter(&(&1 != ""))
     |> Enum.join(" ")
  end

  defp javascript_class(conn) do
    if Turbolinks.enabled?(conn) do
      "js"
    else
      "no-js"
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
