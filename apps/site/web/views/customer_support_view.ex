defmodule Site.CustomerSupportView do
  use Site.Web, :view

  def photo_info(%{"photo" => %Plug.Upload{path: path, filename: filename, content_type: content_type}}) do
    encoded = path
    |> File.read!
    |> Base.encode64

    {encoded, content_type, filename, File.stat!(path).size |> Sizeable.filesize}
  end
  def photo_info(_) do
    nil
  end

  def show_error_message(conn) do
    conn.assigns.show_form && MapSet.size(conn.assigns[:errors]) > 0
  end
end
