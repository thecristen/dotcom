defmodule Site.StyleGuideViewTest do
  # require Phoenix.HTML
  use Site.Web, :view
  use Site.Components.Register
  use Site.StyleGuideView.CssVariables
  use Site.ConnCase, async: true

  test "all components render" do
    @components
    |> Enum.map(&render_components/1)
    |> Enum.each(fn components ->
      components
      |> Enum.each(fn {section, component, _first_char, _last_char} = result ->
        assert {section, component, "<", ">"} == result
      end)
    end)
  end

  test "can get actual hex values for CSS variables that reference other variables" do
    assert Site.StyleGuideView.get_color_value("$brand-secondary") == "#ffce0c"
  end

  test "component_description returns the module documentation" do
    assert Site.StyleGuideView.component_description(:mode_button, :buttons)
      == "\nThe is the documentation for a button.\n\n"
  end

  test "StyleGuideView can get component variants" do
    assert length(Site.StyleGuideView.get_variants(:mode_button, :buttons)) == 2
  end

  test "component_args returns a map of a component's default arguments" do
    assert Site.StyleGuideView.component_args(:mode_button, :buttons) ==
      %{class: nil, id: nil, alert: nil,
        route: %{id: "CR-Fitchburg", key_route?: false, name: "Fitchburg Line", type: 2}}
  end

  test "Can determine if a component's argument needs a comma after it" do
    {_, index} = %Site.Components.Buttons.ModeButton{}
    |> Map.from_struct
    |> Map.keys
    |> Enum.with_index
    |> List.last
    refute Site.StyleGuideView.needs_comma?(:mode_button, :buttons, index) == true
  end

  describe "CSS variable parser" do
    test "scss variables are parsed into the correct structure" do
      assert sorted_color_groups ==
        Site.StyleGuideView.CssVariables.parse_scss_variables("_colors")
        |> Map.keys
        |> Enum.sort
    end

    test "`use Site.StyleGuideView.CssVariables` parses scss variables into an attribute at compile time" do
      assert sorted_color_groups ==
        @colors
        |> Map.keys
        |> Enum.sort
    end
  end

  def render_components({section, components}) do
    components
    |> Enum.map(fn component ->
      html = component
      |> Site.StyleGuideView.render_component(section)
      |> Phoenix.HTML.safe_to_string
      |> String.trim
      {section, component, String.first(html), String.last(html)}
    end)
  end

  def sorted_color_groups do
    Site.StyleGuideView.color_variable_groups |> Enum.sort
  end

end
