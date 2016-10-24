defmodule Site.StyleGuideController do
  use Site.Web, :controller
  use Site.Components.Register
  use Phoenix.HTML

  def index(conn, %{"section" => "content"} = params), do: render_section(conn, params)
  def index(conn, %{"section" => "principles"} = params), do: render_section(conn, params)
  def index(conn, %{"section" => "about"} = params), do: render_section(conn, params)

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

  def show(conn, %{"component_group" => "colors"} = params) do
    conn
    |> assign_styleguide_conn(params)
    |> render("_colors.html")
  end

  def show(conn, %{"component_group" => "typography"} = params) do
    conn
    |> assign_styleguide_conn(params)
    |> render("_typography.html")
  end

  def show(conn, %{"component_group" => component_group} = params) do
    conn
    |> assign_styleguide_conn(params)
    |> assign(:section_components, get_components(component_group))
    |> render("show.html")
  end

  defp assign_styleguide_conn(conn, %{"component_group" => component_group} = params) do
    conn
    |> styleguide_conn(params)
    |> assign(:component_group, String.to_existing_atom(component_group))
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

  @spec get_components(String.t) :: [String.t]
  defp get_components(group) do
    group_atom = String.to_existing_atom(group)
    @components
    |> Enum.find(&match?({^group_atom, _}, &1))
    |> elem(1)
    |> Enum.map(&Atom.to_string/1)
  end
end
