defmodule Content.Helpers do

  @spec field_value(map, String.t) :: any
  def field_value(parsed, field) do
    case parsed[field] do
      [%{"value" => value}] -> value
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

  @spec parse_iso_time(String.t) :: DateTime.t | nil
  def parse_iso_time(time) do
    case Timex.parse(time, "{ISOdate}T{ISOtime}") do
      {:ok, dt} -> Timex.to_datetime(dt, "Etc/UTC")
      _ -> nil
    end
  end

  @spec parse_unix_time(String.t) :: DateTime.t | nil
  def parse_unix_time(unix_string) do
    case Integer.parse(unix_string) do
      {seconds, ""} -> Timex.from_unix(seconds)
      _ -> nil
    end
  end

  @spec parse_updated_at(map) :: DateTime.t | nil
  def parse_updated_at(%{} = data) do
    if changed = field_value(data, "changed") do
      parse_unix_time(changed)
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
    uri = URI.parse(url)

    path = if uri.query do
      "#{uri.path}?#{uri.query}"
    else
      uri.path
    end

    Content.Config.apply(:static, [path])
  end

  @spec parse_link_type(map, String.t) :: String.t | nil
  def parse_link_type(data, field) do
    case data[field] do
      [%{"uri" => "internal:" <> relative_path}] -> relative_path
      [%{"uri" => url}] -> url
      _ -> nil
    end
  end
end
