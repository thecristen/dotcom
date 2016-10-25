defmodule Site.StyleGuideView.CssVariables do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :colors, persist: true
      @colors parse_scss_variables "_colors"

      def color_variable_groups do
        ["Primary Colors", "Secondary Colors", "Grays", "Modes and Lines", "Alerts", "Social Media", "General"]
      end
    end
  end

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
    |> String.split("//\s")
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&parse_scss_section/1)
    |> Map.new
  end

  def parse_scss_section(text) do
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
end
