defmodule Site.PersonController do
  use Site.Web, :controller

  def show(conn, %{"id" => id}) do
    case Content.Repo.person(id) do
      :not_found -> check_cms_or_404(conn)
      person ->
        conn
        |> assign_breadcrumbs(person)
        |> render("show.html", person: person)
    end
  end

  defp assign_breadcrumbs(conn, person) do
    conn
    |> assign(:breadcrumbs, [
        Breadcrumb.build("People"),
        Breadcrumb.build(person.name)
      ])
  end
end
