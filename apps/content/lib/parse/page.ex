defmodule Content.Parse.Page do
  def parse(body) when is_binary(body) do
    with {:ok, json} <- Poison.Parser.parse(body) do
      parse_json(json)
    end
  end

  defp parse_json(%{
        "type" => [%{"target_id" => type}],
        "title" => [%{"value" => title}],
        "body" => [%{"value" => body}],
        "changed" => [%{"value" => timestamp_str}]
                  } = json) do
    with {timestamp, ""} <- Integer.parse(timestamp_str),
         updated_at <- Timex.from_unix(timestamp) do
      {:ok, %Content.Page{
          type: type,
          title: title,
          body: body,
          updated_at: updated_at,
          fields: parse_fields(json)}}
    else
      _ ->
        {:error, "invalid timestamp: #{timestamp_str}"}
    end
  end
  defp parse_json(_) do
    {:error, "missing fields in JSON"}
  end

  defp parse_fields(json) do
    json
    |> Enum.flat_map(&parse_field/1)
    |> Enum.into(%{})
  end

  defp parse_field({"field_" <> _ = key, value}) do
    try do
      apply(__MODULE__, String.to_existing_atom("parse_#{key}"), [value])
    rescue
      ArgumentError -> []
    end
  end
  defp parse_field({_, _}) do
    []
  end

  def parse_field_status([%{"value" => value}]) do
    [status: value]
  end

  def parse_field_featured_image([image]) do
    [featured_image: parse_image(image)]
  end

  def parse_field_photo_gallery(images) do
    [photo_gallery: Enum.map(images, &parse_image/1)]
  end

  def parse_field_downloads(downloads) do
    [downloads: Enum.map(downloads, &parse_file/1)]
  end

  defp parse_image(%{"url" => url, "alt" => alt, "width" => width, "height" => height}) do
    %Content.Page.Image{
      url: Content.Page.Image.rewrite_url(url),
      alt: alt,
      width: String.to_integer(width),
      height: String.to_integer(height)
    }
  end

  defp parse_file(%{"url" => url, "description" => description}) do
    %Content.Page.File{
      url: Content.Page.File.rewrite_url(url),
      description: description,
      type: Content.Page.File.find_type(url)
    }
  end
end
