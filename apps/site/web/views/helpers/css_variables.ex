defmodule Site.StyleGuideView.CssVariables do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :colors, persist: true
      Module.register_attribute __MODULE__, :font_sizes, persist: true
      @colors parse_scss_variables "_colors"
      @font_sizes "_variables" |> parse_scss_variables |> Map.get("Font Sizes")

      def color_variable_groups do
        ["Primary Colors", "Secondary Colors", "Background Colors", "Gradients", "Grays", "Modes and Lines", "Alerts", "Social Media", "General"]
      end
    end
  end

  @doc """
    Reads a css file and returns a map of variables it contains. Begin parsing with "// style-guide --section {Section Name}"
    and stops at "// style-guide --ignore". For example, parsing a file that's structured like this...

    ```
    $variable-1: 24px;
    $variable-2: 36px;

    // style-guide --section Spacing Values
    $spacing-1: 1rem;
    $spacing-2: 2rem;
    $spacing-3: 3rem;

    // style-guide --ignore
    $border: 1px solid $gray;
    $border-heavy: 3px solid $gray-darker;

    // style-guide --section Colors
    $foo: red;
    $bar: blue;

    ```

    ...would produce this map:
    ```
    %{
      "Spacing Values" => %{
        "$spacing-1" => "1rem",
        "$spacing-2" => "2rem",
        "$spacing-3" => "3rem"
      },
      "Colors" => %{
        "$foo" => "red",
        "$bar" => "blue"
      }
    }
    ```
  """
  def parse_scss_variables(file_name) do
    File.cwd!
    |> String.split("/apps/site")
    |> List.first
    |> Path.join("/apps/site/web/static/css/#{file_name}.scss")
    |> File.read!
    |> parse_scss_file
  end

  def parse_scss_file(text) do
    text
    |> String.split("//\sstyle-guide\s")
    |> Enum.reject(&(&1 == "")) # remove empty lines
    |> Enum.reduce([], &reject_ignore_lines/2)
    |> Enum.map(&parse_scss_section/1)
    |> Map.new
  end

  defp parse_scss_section(text) do
    [section|variables] = String.split(text, "\n")
    values = variables
    |> Enum.map(&parse_scss_variable/1)
    |> Enum.reject(fn {k,_} -> k == "" end)
    |> Map.new
    {section, values}
  end

  def parse_scss_variable(text) do
    [key|val] = text
    |> String.trim
    |> String.replace(";", "")
    |> String.split(":")
    |> Enum.map(&(String.trim(&1)))
    {key, List.first(val)}
  end

  defp reject_ignore_lines("--section " <> content, acc), do: acc ++ [content]
  defp reject_ignore_lines(_, acc), do: acc

end
