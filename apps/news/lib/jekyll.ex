defmodule News.Jekyll do
  @moduledoc """

  Parses a string/file in Jekyll [https://jekyllrb.com/docs/posts/] format
  into a News.Post structure.

  """

  @front_matter_sep "---\n"

  def parse(str) do
    [_, yaml, body] = str
    |> String.split(@front_matter_sep, parts: 3)

    %News.Post{
      attributes: yaml |> parse_yaml,
      body: body |> String.strip
    }
  end

  @doc """

  Given a filename with a Jekyll-style post, parses it into a News.Post struct.

  If include_body is false, then do not read the file to parse the body. This
  is useful for creating stub structures from a list of filenames.

  """
  def parse_file(filename) do
    try do
      filename
      |> File.read!
      |> parse
      |> add_file_attributes(filename)
    catch
      err -> throw "Error while parsing #{filename}: #{inspect err}"
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
