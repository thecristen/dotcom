defmodule News.Jekyll do
  @moduledoc """

  Parses a string/file in Jekyll [https://jekyllrb.com/docs/posts/] format
  into a News.Post structure.

  """

  @front_matter_sep "---\n"

  @spec parse(binary) :: {:ok, News.Post.t} | {:error, any}
  def parse(str) do
    try do
      case String.split(str, @front_matter_sep, parts: 3) do
        [_, yaml, body] ->
          {:ok, %News.Post{
              attributes: yaml |> parse_yaml,
              body: body |> String.strip}
          }
        _ ->
          {:error, "unable to parse YAML"}
      end
    catch # yamlerl throws exceptions :(
      exc -> {:error, exc}
    end
  end

  defp parse_yaml(yaml) do
    yaml
    |> :yamerl_constr.string # parse the YAML
    |> Enum.at(0)
    |> Enum.map(fn({k, v}) -> {to_string(k), to_string(v)} end) # convert the char lists to strings
    |> Enum.into(%{})
  end
end
