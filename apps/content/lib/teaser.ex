defmodule Content.Teaser do
  defstruct [
    :image_path,
    :path,
    :text,
    :title,
    :topic,
    :type,
    :date
  ]

  @type type :: :news_entry
              | :event
              | :project
              | :page
              | :project_update

  @type t :: %__MODULE__{
    image_path: String.t,
    path: String.t,
    text: String.t,
    title: String.t,
    topic: String.t,
    type: type,
    date: Date.t | nil
  }

  @spec from_api(map) :: __MODULE__.t
  def from_api(%{
    "image_uri" => image_path,
    "path" => path,
    "text" => text,
    "title" => title,
    "type" => type,
    "topic" => topic
  } = data) do
    %__MODULE__{
      image_path: image_path,
      path: path,
      text: text,
      title: title,
      topic: topic,
      type: type(type),
      date: date(data)
    }
  end

  @spec date(map) :: Date.t | nil
  defp date(%{"type" => "news_entry", "posted" => date}) do
    do_date(date)
  end
  defp date(%{"changed" => date}) do
    do_date(date)
  end

  @spec do_date(String.t) :: Date.t | nil
  defp do_date(date) do
    case Timex.parse(date, "{YYYY}-{M}-{D}") do
      {:ok, dt} -> NaiveDateTime.to_date(dt)
      {:error, _} -> nil
    end
  end

  @spec type(String.t) :: type
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
