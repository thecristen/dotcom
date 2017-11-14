defmodule SiteWeb.StyleGuideViewTest do
  # require Phoenix.HTML
  use SiteWeb, :view
  use Site.Components.Register
  use SiteWeb.StyleGuideView.CssVariables
  use SiteWeb.ConnCase, async: true

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
    assert SiteWeb.StyleGuideView.get_css_value("$brand-secondary", :colors) == "#ffce0c"
  end

  test "component_description returns the module documentation" do
    assert SiteWeb.StyleGuideView.component_description(:mode_button_list, :buttons)
      =~ "Renders a ButtonGroup with alert icons and"
  end

  test "StyleGuideView can get component variants" do
    assert [{name, %SvgIcon{}}|_] = SiteWeb.StyleGuideView.get_variants(:svg_icon, :icons)
    assert is_binary(name)
  end

  test "component_args returns a map of a component's default arguments" do
    assert SiteWeb.StyleGuideView.component_args(:button_group, :buttons) ==
      %ButtonGroup{class: "", id: nil, links: [
                     {"Sample link 1", SiteWeb.Router.Helpers.page_path(SiteWeb.Endpoint, :index)},
                     {"Sample link 2", SiteWeb.Router.Helpers.page_path(SiteWeb.Endpoint, :index)}
                     ]}
  end

  test "Can determine if a component's argument needs a comma after it" do
    {_, index} = %ModeButtonList{}
    |> Map.from_struct
    |> Map.keys
    |> Enum.with_index
    |> List.last
    refute SiteWeb.StyleGuideView.needs_comma?(:mode_button_list, :buttons, index) == true
  end

  def css_file do
    """
    $variable-1: foo;
    $variable-2: foo;

    // style-guide --section Include In Results
    $variable-3: bar;
    $variable-4: bar;
    $variable-5: bar;

    // style-guide --ignore
    $varible-6: baz;

    // style-guide --section Also include
    $variable-7: baz;
    """
  end

  describe "&parse_scss_file/1" do
    test "only parses where it's supposed to" do
      result = SiteWeb.StyleGuideView.CssVariables.parse_scss_file(css_file())
      assert result == %{
        "Include In Results" => %{
          "$variable-3" => "bar",
          "$variable-4" => "bar",
          "$variable-5" => "bar"
        },
        "Also include" => %{
          "$variable-7" => "baz"
        }
      }
    end
  end

  describe "CSS variable parser" do
    test "scss variables are parsed into the correct structure" do
      assert sorted_color_groups() ==
        SiteWeb.StyleGuideView.CssVariables.parse_scss_variables("_colors")
        |> Map.keys
        |> Enum.sort
    end

    test "`use SiteWeb.StyleGuideView.CssVariables` parses scss variables into an attribute at compile time" do
      assert sorted_color_groups() ==
        @colors
        |> Map.keys
        |> Enum.sort
    end
  end

  def render_components({section, components}) do
    components
    |> Enum.map(fn component ->
      html = component
      |> SiteWeb.StyleGuideView.render_component(section)
      |> Phoenix.HTML.safe_to_string
      |> String.trim
      {section, component, String.first(html), String.last(html)}
    end)
  end

  def sorted_color_groups do
    SiteWeb.StyleGuideView.color_variable_groups |> Enum.sort
  end

end
