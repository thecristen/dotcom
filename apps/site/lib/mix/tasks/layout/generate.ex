defmodule Mix.Tasks.Layout.Generate do
  use Mix.Task
  use Phoenix.View, root: "lib/site_web/templates"
  require SiteWeb.LayoutView

  @output_folder Application.app_dir(:site, "priv/compiled_header_footer")

  def run(args) do
    {opts, [], []} = OptionParser.parse(args, switches: [output_folder: :string])

    output_folder = Keyword.get(opts, :output_folder, @output_folder)

    :ok = File.mkdir_p(output_folder)

    {:ok, _} = Application.ensure_all_started(:site)

    :ok = File.cp(js_file_path(), Path.join(output_folder, "collapse.js"))

    [:ok, :ok] =
      ["_header.html", "_footer.html"]
      |> Enum.map(&generate_html/1)
      |> Enum.map(&write_to_file(&1, output_folder))
  end

  def generate_html(file_name) do
    assigns = %{
      exclude_dropdowns: true,
      exclude_google_translate: true,
      conn: SiteWeb.Endpoint
    }

    html = Phoenix.View.render_to_string(SiteWeb.LayoutView, file_name, assigns)

    {file_name, html}
  end

  defp write_to_file({file_name, html}, output_folder) do
    output_folder
    |> Path.join(file_name)
    |> File.write(html)
  end

  def js_file_path do
    :site
    |> Application.app_dir()
    |> Path.join("../../../..")
    |> Path.join("apps/site/assets/node_modules/bootstrap/dist/js/umd/collapse.js")
    |> Path.expand()
  end
end
