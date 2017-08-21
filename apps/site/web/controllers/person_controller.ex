defmodule Site.PersonController do
  use Site.Web, :controller

  def show(conn, %{"id" => id}) do
    person = Content.Repo.person!(id)

    conn
    |> assign_breadcrumbs(person)
    |> render("show.html", person: person)
  end

  defp assign_breadcrumbs(conn, person) do
    conn
    |> assign(:breadcrumbs, [
        Breadcrumb.build("People"),
        Breadcrumb.build(person.name)
      ])
  end
end
