defmodule SiteWeb.ProjectViewTest do
  @moduledoc false
  use SiteWeb.ConnCase, async: true

  @conn %Plug.Conn{}
  @project %Content.Project{id: 1, updated_on: Timex.now, posted_on: Timex.now, path_alias: nil}
  @events [%Content.Event{id: 1, start_time: Timex.now, end_time: Timex.now, path_alias: nil}]
  @updates [%Content.ProjectUpdate{
    id: 1, title: "title", teaser: "teaser", posted_on: Timex.now, path_alias: nil, project_id: 1}]

  describe "_contact.html" do
    test ".project-contact is not rendered if no data is available" do
    project = @project

      output = "show.html"
        |> SiteWeb.ProjectView.render(project: project, updates: @updates,
                                      conn: @conn, upcoming_events: @events, past_events: @events)
        |> Phoenix.HTML.safe_to_string

      refute output =~ "project-contact"
    end

    test ".project-contact is rendered if contact_information is available" do
      project = %{@project | contact_information: "present"}

      output = "show.html"
        |> SiteWeb.ProjectView.render(project: project, updates: @updates,
                                      conn: @conn, upcoming_events: @events, past_events: @events)
        |> Phoenix.HTML.safe_to_string

      assert output =~ "project-contact"
    end

    test ".project-contact is rendered if media_email is available" do
      project = %{@project | media_email: "present"}

      output = "show.html"
        |> SiteWeb.ProjectView.render(project: project, updates: @updates,
                                      conn: @conn, upcoming_events: @events, past_events: @events)
        |> Phoenix.HTML.safe_to_string

      assert output =~ "project-contact"
    end

    test ".project-contact is rendered if media_phone is available" do
      project = %{@project | media_phone: "present"}

      output = "show.html"
        |> SiteWeb.ProjectView.render(project: project, updates: @updates,
                                      conn: @conn, upcoming_events: @events, past_events: @events)
        |> Phoenix.HTML.safe_to_string

      assert output =~ "project-contact"
    end

    test ".contact-element-contact is not rendered if contact_information is not available" do
      project = %{@project | media_email: "present", media_phone: "present"}

      output = "show.html"
        |> SiteWeb.ProjectView.render(project: project, updates: @updates,
                                      conn: @conn, upcoming_events: @events, past_events: @events)
        |> Phoenix.HTML.safe_to_string

      refute output =~ "contact-element-contact"
    end

    test ".contact-element-email is not rendered if media_email is not available" do
      project = %{@project | contact_information: "present", media_phone: "present"}

      output = "show.html"
        |> SiteWeb.ProjectView.render(project: project, updates: @updates,
                                      conn: @conn, upcoming_events: @events, past_events: @events)
        |> Phoenix.HTML.safe_to_string

      refute output =~ "contact-element-email"
    end

    test ".contact-element-phone is not rendered if media_phone is not available" do
      project = %{@project | contact_information: "present", media_email: "present"}

      output = "show.html"
        |> SiteWeb.ProjectView.render(project: project, updates: @updates,
                                      conn: @conn, upcoming_events: @events, past_events: @events)
        |> Phoenix.HTML.safe_to_string

      refute output =~ "contact-element-phone"
    end

    test ".contact-element-contact is rendered if contact_information is available" do
      project = %{@project | contact_information: "present"}

      output = "show.html"
        |> SiteWeb.ProjectView.render(project: project, updates: @updates,
                                      conn: @conn, upcoming_events: @events, past_events: @events)
        |> Phoenix.HTML.safe_to_string

      assert output =~ "contact-element-contact"
    end

    test ".contact-element-email is rendered if media_email is available" do
      project = %{@project | media_email: "present"}

      output = "show.html"
        |> SiteWeb.ProjectView.render(project: project, updates: @updates,
                                      conn: @conn, upcoming_events: @events, past_events: @events)
        |> Phoenix.HTML.safe_to_string

      assert output =~ "contact-element-email"
    end

    test ".contact-element-phone is rendered if media_phone is available" do
      project = %{@project | media_phone: "present"}

      output = "show.html"
        |> SiteWeb.ProjectView.render(project: project, updates: @updates,
                                      conn: @conn, upcoming_events: @events, past_events: @events)
        |> Phoenix.HTML.safe_to_string

      assert output =~ "contact-element-phone"
    end
  end
end
