defmodule Site.StyleGuideController do
  use Site.Web, :controller
  use Site.Components.Register
  use Phoenix.HTML

  @content_sections [:audience_goals_tone, :grammar_and_mechanics, :terms]

  def index(conn, %{"section" => "content"}) do
    redirect conn, to: "/style_guide/content/audience_goals_tone"
  end
  def index(conn, %{"section" => "components"}) do
    redirect conn, to: "/style_guide/components/typography"
  end
  def index(conn, %{"section" => _} = params), do: render_section(conn, params)

  def index(conn, params) do
    conn
    |> assign_styleguide_conn(params)
    |> render("index.html")
  end

  def render_section(conn, %{"section" => section} = params) do
    conn
    |> assign_styleguide_conn(params)
    |> render("#{section}.html")
  end

  def show(conn, %{"subpage" => "colors"} = params) do
    conn
    |> assign_styleguide_conn(params)
    |> render("_colors.html")
  end

  def show(conn, %{"subpage" => "typography"} = params) do
    conn
    |> assign_styleguide_conn(params)
    |> render("_typography.html")
  end

  def show(conn, %{"section" => "content", "subpage" => subpage} = params) do
    conn
    |> assign_styleguide_conn(params)
    |> render("_#{subpage}.html")
  end

  def show(conn, %{"subpage" => component_group} = params) do
    conn
    |> assign_styleguide_conn(params)
    |> assign(:section_components, get_components(component_group))
    |> render("show.html")
  end

  defp assign_styleguide_conn(conn, %{"subpage" => subpage} = params) do
    conn
    |> styleguide_conn(params)
    |> assign_all_subpages(params)
    |> assign(:subpage, String.to_existing_atom(subpage))
  end

  defp assign_styleguide_conn(conn, params) do
    conn
    |> styleguide_conn(params)
  end

  defp styleguide_conn(conn, %{"section" => section}) do
    conn
    |> styleguide_layout
    |> assign(:section, String.to_existing_atom(section))
  end

  defp styleguide_conn(conn, _) do
    conn
    |> styleguide_layout
    |> assign(:section, nil)
  end

  defp styleguide_layout(conn) do
    conn
    |> put_layout("style_guide.html")
    |> assign(:components, @components)
  end

  @spec get_components(String.t) :: [atom]
  defp get_components(group) do
    group_atom = String.to_existing_atom(group)
    @components
    |> Enum.find(&match?({^group_atom, _}, &1))
    |> elem(1)
  end

  def assign_all_subpages(conn, %{"section" => "components"}) do
    conn
    |> assign(:all_subpages, [:typography | [:colors | Keyword.keys(@components)]])
  end

  def assign_all_subpages(conn, %{"section" => "content"}) do
    conn
    |> assign(:all_subpages, @content_sections)
  end
end
