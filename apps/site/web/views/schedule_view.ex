defmodule Site.ScheduleView do
  use Site.Web, :view

  def svg(_conn, path) do
    svg_content = :site
    |> Application.app_dir
    |> Path.join("priv/static" <> path)
    |> File.read!
    |> String.split("\n")
    |> Enum.drop(1) # drop the <?xml> header
    |> Enum.join("")

    raw svg_content
  end
end
