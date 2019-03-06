defmodule Content.Teaser do
  defstruct [
    :image,
    :path,
    :text,
    :title,
    :topic,
    :id,
    :type,
    :date
  ]

  alias Content.Field.Image

  @type type ::
          :news_entry
          | :event
          | :project
          | :page
          | :project_update

  @type t :: %__MODULE__{
          image: Image.t() | nil,
          path: String.t(),
          text: String.t(),
          title: String.t(),
          topic: String.t(),
          id: String.t(),
          type: type,
          date: Date.t() | nil
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
          "nid" => id
        } = data
      ) do
    %__MODULE__{
      image: image(image_path, image_alt),
      path: path,
      text: text,
      title: title,
      topic: topic,
      id: id,
      type: type(type),
      date: date(data)
    }
  end

  @spec date(map) :: Date.t() | nil
  defp date(%{"type" => "news_entry", "posted" => date}) do
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

  @spec type(String.t()) :: type
  for atom <- ~w(
    news_entry
    event
    project
    page
    project_update
  )a do
    str = Atom.to_string(atom)
    defp type(unquote(str)), do: unquote(atom)
  end
end
