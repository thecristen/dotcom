defmodule Content.Teaser do
  @moduledoc """
  A short, simplified representation of any content type.
  """

  import Content.Helpers, only: [content_type: 1]

  alias Content.{CMS, Field.Image}

  defstruct [
    :image,
    :path,
    :text,
    :title,
    :topic,
    :id,
    :type,
    :date,
    :routes
  ]

  @type t :: %__MODULE__{
          image: Image.t() | nil,
          path: String.t(),
          text: String.t(),
          title: String.t(),
          topic: String.t(),
          id: String.t(),
          type: CMS.type(),
          date: Date.t() | nil,
          routes: [String.t()]
        }

  @spec from_api(map) :: __MODULE__.t()
  def from_api(
        %{
          "image_uri" => image_path,
          "image_alt" => image_alt,
          "path" => path,
          "text" => text,
          "title" => title,
          "type" => type,
          "topic" => topic,
          "nid" => id,
          "field_related_transit" => route_data
        } = data
      ) do
    %__MODULE__{
      image: image(image_path, image_alt),
      path: path,
      text: text,
      title: title,
      topic: topic,
      id: id,
      type: content_type(type),
      date: date(data),
      routes: routes(route_data)
    }
  end

  @spec date(map) :: Date.t() | nil
  defp date(%{"type" => type, "posted" => date}) when type in ["news_entry", "project_update"] do
    do_date(date)
  end

  defp date(%{"type" => "project", "updated" => updated, "changed" => changed}) do
    case updated do
      "" -> do_date(changed)
      _ -> do_date(updated)
    end
  end

  defp date(%{"changed" => date}) do
    do_date(date)
  end

  @spec do_date(String.t()) :: Date.t() | nil
  defp do_date(date) do
    case Timex.parse(date, "{YYYY}-{M}-{D}") do
      {:ok, dt} -> NaiveDateTime.to_date(dt)
      {:error, _} -> nil
    end
  end

  @spec image(String.t(), String.t()) :: Image.t() | nil
  defp image("", _), do: nil
  defp image(uri, alt), do: struct(Image, url: uri, alt: alt)

  @spec routes([map()]) :: [map()]
  defp routes(route_data) do
    route_data
    |> Enum.map(& &1["data"])
    |> Enum.map(&route_metadata/1)
    |> Enum.reject(&is_nil/1)
  end

  # Maps the tagged CMS route term, it's group, and it's parent mode.
  # Parent mode is useful for "misc" group terms that don't have matching
  # route IDs in Elixir's route repository, such as "local_bus".
  @spec route_metadata(map()) :: map()
  defp route_metadata(route_data) do
    Map.new(
      id: route_data["gtfs_id"],
      group: route_data["gtfs_group"],
      mode: route_data["gtfs_ancestry"]["mode"] |> List.first()
    )
  end
end
