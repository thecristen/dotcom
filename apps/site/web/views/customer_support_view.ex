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
end
