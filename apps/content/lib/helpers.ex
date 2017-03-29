defmodule Content.Helpers do

  @spec field_value(map, String.t) :: any
  def field_value(parsed, field) do
    case parsed[field] do
      [%{"value" => value}] -> value
      _ -> nil
    end
  end

  @spec parse_time(String.t) :: DateTime.t | nil
  def parse_time(unix_string) do
    case Integer.parse(unix_string) do
      {seconds, ""} -> Timex.from_unix(seconds)
      _ -> nil
    end
  end

  @spec handle_html(String.t | nil) :: Phoenix.HTML.safe
  def handle_html(html) do
    (html || "")
    |> HtmlSanitizeEx.html5
    |> rewrite_static_file_links
    |> Phoenix.HTML.raw
  end

  @spec parse_body(map) :: Phoenix.HTML.safe
  def parse_body(%{} = data) do
    data
    |> field_value("body")
    |> handle_html
  end

  @spec parse_featured_image(map) :: Content.Field.Image.t | nil
  def parse_featured_image(%{} = data) do
    case data["field_featured_image"] do
      [image] -> Content.Field.Image.from_api(image)
      _ -> nil
    end
  end

  @spec parse_updated_at(map) :: DateTime.t | nil
  def parse_updated_at(%{} = data) do
    case field_value(data, "changed") do
      nil -> nil
      changed -> parse_time(changed)
    end
  end

  @spec rewrite_static_file_links(String.t) :: String.t
  def rewrite_static_file_links(body) do
    static_path = Content.Config.static_path
    Regex.replace(~r/"(#{static_path}[^"]+)"/, body, fn _, path ->
      ['"', Content.Config.apply(:static, [path]), '"']
    end)
  end

  @spec rewrite_url(String.t) :: String.t
  def rewrite_url(url) when is_binary(url) do
    root = case Content.Config.root do
             nil -> "missing-host-should-not-match"
             host -> String.replace_suffix(host, "/", "")
           end
    static_path = Content.Config.static_path

    Regex.replace(~r/^#{root}(#{static_path}[^"]+)/, url, fn _, path ->
      Content.Config.apply(:static, [path])
    end)
  end
end
