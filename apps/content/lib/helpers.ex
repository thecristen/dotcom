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
    |> Content.CustomHTML5Scrubber.html5
    |> rewrite_static_file_links
    |> Phoenix.HTML.raw
  end

  @spec parse_body(map) :: Phoenix.HTML.safe
  def parse_body(%{} = data) do
    data
    |> field_value("body")
    |> handle_html
  end

  @spec parse_files(map, String.t) :: [Content.Field.File.t]
  def parse_files(%{} = data, field) do
    data
    |> Map.get(field, [])
    |> Enum.map(&Content.Field.File.from_api/1)
  end

  @spec parse_image(map, String.t) :: Content.Field.Image.t | nil
  def parse_image(%{} = data, field) do
    case parse_images(data, field) do
      [image] -> image
      [] -> nil
    end
  end

  @spec parse_images(map, String.t) :: [Content.Field.Image.t] | []
  def parse_images(%{} = data, field) do
    data
    |> Map.get(field, [])
    |> Enum.map(&Content.Field.Image.from_api/1)
  end

  @spec parse_iso_datetime(String.t) :: DateTime.t | nil
  def parse_iso_datetime(time) do
    case Timex.parse(time, "{ISOdate}T{ISOtime}") do
      {:ok, dt} -> Timex.to_datetime(dt, "Etc/UTC")
      _ -> nil
    end
  end

  @spec parse_date(map, String.t) :: Date.t | nil
  def parse_date(data, field) do
    case data[field] do
      [%{"value" => date}] -> parse_date_string(date, "{YYYY}-{0M}-{0D}")
      _ -> nil
    end
  end

  @spec parse_date_string(String.t, String.t) :: Date.t | nil
  defp parse_date_string(date, format_string) do
    case Timex.parse(date, format_string) do
      {:error, _message} -> nil
      {:ok, naive_datetime} -> NaiveDateTime.to_date(naive_datetime)
    end
  end

  @spec parse_link(map, String.t) :: Content.Field.Link.t | nil
  def parse_link(%{} = data, field) do
    case data[field] do
      [link] -> Content.Field.Link.from_api(link)
      _ -> nil
    end
  end

  @spec parse_paragraphs(map) :: [Content.Paragraph.t]
  def parse_paragraphs(data) do
    data
    |> Map.get("field_paragraphs", [])
    |> Enum.map(&Content.Paragraph.from_api/1)
  end

  @spec rewrite_static_file_links(String.t) :: String.t
  defp rewrite_static_file_links(body) do
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

  @spec int_or_string_to_int(integer | String.t | nil) :: integer | nil
  def int_or_string_to_int(nil), do: nil
  def int_or_string_to_int(num) when is_integer(num), do: num
  def int_or_string_to_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {int, ""} -> int
      _ -> nil
    end
  end
end
