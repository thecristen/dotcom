defmodule Content.Banner do
  @moduledoc """

  Represents the "Banner" content type in the CMS. Banners are
  displayed at the top of the homepage.

  """

  import Content.Helpers, only: [field_value: 2, parse_link: 2, category: 1]
  alias Content.Field.Image
  alias Content.Field.Link

  defstruct [
    blurb: "",
    link: %Link{},
    thumb: nil,
    banner_type: :default,
    text_position: :left,
    category: :unknown,
    mode: :unknown,
    updated_on: "",
    title: "",
  ]

  @type mode :: :subway
              | :bus
              | :commuter_rail
              | :ferry
              | :red_line
              | :orange_line
              | :blue_line
              | :green_line
              | :silver_line
              | :the_ride

  @type t :: %__MODULE__{
    blurb: String.t | nil,
    link: Link.t | nil,
    thumb: Image.t | nil,
    banner_type: :default | :important,
    text_position: :left | :right,
    category: Content.Helpers.category,
    mode: mode | :unknown,
    title: String.t,
    updated_on: String.t
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    %__MODULE__{
      blurb: field_value(data, "field_in_blurb") || field_value(data, "title") || "",
      link: parse_link(data, "field_in_link"),
      thumb: parse_image(data["field_image"]) || parse_image(data["field_in_thumb"]),
      banner_type: data |> field_value("field_banner_type") |> banner_type(),
      text_position: data |> field_value("field_text_position") |> text_position(),
      category: category(data),
      mode: data |> field_value("field_mode") |> mode(),
      updated_on: data |> field_value("field_updated_on") |> updated_on(),
      title: field_value(data, "title") || ""
    }
  end

  @spec parse_image([map]) :: Image.t | nil
  defp parse_image([%{} = api_image]), do: Image.from_api(api_image)
  defp parse_image(_), do: nil

  @spec banner_type(String.t | nil) :: :important | :default
  defp banner_type("important"), do: :important
  defp banner_type(_), do: :default

  @spec text_position(String.t | nil) :: :left | :right
  defp text_position("right"), do: :right
  defp text_position(_), do: :left

  @spec mode(String.t | nil) :: mode | :unknown
  for name <- ~w(subway bus commuter_rail ferry red_line orange_line blue_line green_line silver_line the_ride) do
    atom = String.to_atom(name)
    defp mode(unquote(name)), do: unquote(atom)
  end
  defp mode(_), do: :unknown

  @spec updated_on(String.t | nil) :: String.t
  defp updated_on(date) when is_binary(date) do
    date
    |> Timex.parse("{YYYY}-{M}-{D}")
    |> do_updated_on()
  end
  defp updated_on(_) do
    ""
  end

  defp do_updated_on({:ok, date}) do
    case Timex.format(date, "{Mfull} {D}, {YYYY}") do
      {:ok, formatted} -> formatted
      {:error, _} -> ""
    end
  end
  defp do_updated_on(_) do
    ""
  end
end
