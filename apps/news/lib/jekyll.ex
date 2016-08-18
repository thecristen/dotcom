defmodule News.Jekyll do
  @moduledoc """

  Parses a string/file in Jekyll [https://jekyllrb.com/docs/posts/] format
  into a News.Post structure.

  """

  @front_matter_sep "---\n"

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

  @doc """

  Given a filename with a Jekyll-style post, parses it into a News.Post struct.

  If include_body is false, then do not read the file to parse the body. This
  is useful for creating stub structures from a list of filenames.

  """
  def parse_file!(filename) do
    case parse_file(filename) do
      {:ok, post} ->
        post
      {:error, error} ->
        throw "Error while parsing #{filename}: #{inspect error}"
    end
  end

  def parse_file(filename) do
    with {:ok, data} <- File.read(filename),
         {:ok, post} <- parse(data) do
      {:ok, post |> add_file_attributes(filename)}
    end
  end

  defp parse_yaml(yaml) do
    yaml
    |> :yamerl_constr.string # parse the YAML
    |> Enum.at(0)
    |> Enum.map(fn({k, v}) -> {to_string(k), to_string(v)} end) # convert the char lists to strings
    |> Enum.into(%{})
  end

  defp add_file_attributes(post, filename) do
    [year_str, month_str, day_str, id] = filename
    |> Path.basename
    |> Path.rootname
    |> String.split("-", parts: 4)
    %News.Post{post |
               filename: filename,
               id: id,
               date: {String.to_integer(year_str),
                      String.to_integer(month_str),
                      String.to_integer(day_str)}}
  end
end
