defmodule Content.Helpers do
  def field_value(parsed, field) do
    case parsed[field] do
      [%{"value" => value}] -> value
      _ -> nil
    end
  end

  def rewrite_static_file_links(body) do
    static_path = Content.Config.static_path
    Regex.replace(~r/"(#{static_path}[^"]+)"/, body, fn _, path ->
      ['"', Content.Config.apply(:static, [path]), '"']
    end)
  end

  def parse_time(unix_string) do
    case Integer.parse(unix_string) do
      {seconds, ""} -> Timex.from_unix(seconds)
      _ -> nil
    end
  end

  def handle_html(html) do
    html = (html || "")
    |> HtmlSanitizeEx.html5
    |> rewrite_static_file_links

    {:safe, html}
  end
end
