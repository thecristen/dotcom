defmodule Site.LayoutView do
  use Site.Web, :view

  def bold_if_active(conn, path, text) do
    if String.starts_with?(conn.request_path, path) do
      raw "<strong>#{text}</strong>"
    else
      raw text
    end
  end
end
