defmodule Content.Teaser do
  @moduledoc """
  A short, simplified representation of any our content types.
  Fed by the /cms/teasers CMS API endpoint.
  """
  import Content.Helpers, only: [content_type: 1, content: 1, int_or_string_to_int: 1]

  alias Content.{CMS, Field.Image}

  @enforce_keys [:id, :type, :path, :title]
  defstruct [
    :id,
    :type,
    :path,
    :title,
    image: nil,
    text: nil,
    topic: nil,
    date: nil,
    location: nil,
    routes: []
  ]

  @type t :: %__MODULE__{
          id: integer,
          type: CMS.type(),
          path: String.t(),
          title: String.t(),
          image: Image.t() | nil,
          text: String.t() | nil,
          topic: String.t() | nil,
          date: Date.t() | DateTime.t() | nil,
          location: String.t() | nil,
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
      id: int_or_string_to_int(id),
      type: content_type(type),
      path: path,
      title: content(title),
      image: image(image_path, image_alt),
      text: content(text),
      topic: content(topic),
      location: data |> location() |> content(),
      date: date(data),
      routes: routes(route_data)
    }
  end

  @spec date(map) :: Date.t() | nil
  # news_entry and project_update types share a common "Posted On" date field (both are required).
  defp date(%{"type" => type, "posted" => date}) when type in ["news_entry", "project_update"] do
    do_date(date)
  end

  # project types have a required "Updated On" date field.
  defp date(%{"type" => "project", "updated" => date}) do
    do_date(date)
  end

  # event types have a required "Start Time" date field.
  defp date(%{"type" => "event", "start" => date}) do
    do_datetime(date)
  end

  # Emulate /cms/teasers endpoint and fall back to creation date when:
  # A: :sort_by and :sort_order have not been set OR
  # B: The results are all basic page type content items.
  # *: All content types have this core field date.
  defp date(%{"created" => date}) do
    do_date(date)
  end

  @spec do_date(String.t()) :: Date.t() | nil
  defp do_date(date) do
    case Timex.parse(date, "{YYYY}-{M}-{D}") do
      {:ok, dt} -> NaiveDateTime.to_date(dt)
      {:error, _} -> nil
    end
  end

  # The Event start time includes time and timezone data
  @spec do_datetime(String.t()) :: DateTime.t() | nil
  defp do_datetime(date) do
    case DateTime.from_iso8601(date) do
      {:ok, dt, offset} -> DateTime.add(dt, offset)
      {:error, _} -> nil
    end
  end

  @spec image(String.t(), String.t()) :: Image.t() | nil
  defp image("", _), do: nil
  defp image(uri, alt), do: struct(Image, url: uri, alt: alt)

  # Event location is sent in the form of a pipe-separated string:
  # Ex: "place|address|city|state" (any of the slots may be "").
  @spec location(map()) :: String.t()
  defp location(%{"location" => piped_string}) do
    piped_string
    |> String.split("|", trim: true)
    |> Enum.intersperse(" • ")
    |> List.to_string()
  end

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
