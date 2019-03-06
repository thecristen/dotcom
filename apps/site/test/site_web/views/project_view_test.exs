defmodule SiteWeb.ProjectViewTest do
  use SiteWeb.ConnCase, async: true

  alias Content.{Event, Field.Image, Paragraph.CustomHTML, Project, ProjectUpdate}
  alias Phoenix.HTML
  alias Plug.Conn
  alias SiteWeb.ProjectView

  @now Timex.now()
  @conn %Conn{}
  @project %Project{
    id: 1,
    updated_on: @now,
    posted_on: @now,
    path_alias: nil,
    start_year: @now.year,
    status: "In Progress"
  }
  @events [%Event{id: 1, start_time: @now, end_time: @now, path_alias: nil}]
  @updates [
    %ProjectUpdate{
      id: 1,
      title: "title",
      teaser: "teaser",
      posted_on: @now,
      path_alias: nil,
      project_id: 1,
      image: nil
    }
  ]

  describe "show.html" do
    test "if paragraphs are present, hide timeline, status, body, gallery, and download components" do
      project =
        @project
        |> Map.put(:paragraphs, [%CustomHTML{body: "Paragraph content"}])

      output =
        "show.html"
        |> ProjectView.render(
          project: project,
          updates: @updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      assert output =~ "Paragraph content"
      refute output =~ "state-of-the-art safety features"
      refute output =~ "wollaston-stairs-and-elevators-to-access-platform-800_1.jpeg"
      refute output =~ "l-content-files"
      refute output =~ "Timeline:"
      refute output =~ "Status:"
    end

    test "if paragraphs are not present, show timeline, status" do
      project = @project

      output =
        "show.html"
        |> ProjectView.render(
          project: project,
          updates: @updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      assert output =~ "Timeline:"
      assert output =~ "Status:"
    end

    test "timeline, status, and contact blocks are not required" do
      output =
        "show.html"
        |> ProjectView.render(
          project: %Project{
            id: 1,
            updated_on: @now,
            posted_on: @now,
            path_alias: nil
          },
          updates: @updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      assert output =~ "About the Project"
      assert output =~ "Project Updates"
    end
  end

  describe "_contact.html" do
    test ".project-contact is not rendered if no data is available" do
      project = @project

      output =
        "show.html"
        |> ProjectView.render(
          project: project,
          updates: @updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      refute output =~ "project-contact"
    end

    test ".project-contact is rendered if contact_information is available" do
      project = %{@project | contact_information: "present"}

      output =
        "show.html"
        |> ProjectView.render(
          project: project,
          updates: @updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      assert output =~ "project-contact"
    end

    test ".project-contact is rendered if media_email is available" do
      project = %{@project | media_email: "present"}

      output =
        "show.html"
        |> ProjectView.render(
          project: project,
          updates: @updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      assert output =~ "project-contact"
    end

    test ".project-contact is rendered if media_phone is available" do
      project = %{@project | media_phone: "present"}

      output =
        "show.html"
        |> ProjectView.render(
          project: project,
          updates: @updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      assert output =~ "project-contact"
    end

    test ".contact-element-contact is not rendered if contact_information is not available" do
      project = %{@project | media_email: "present", media_phone: "present"}

      output =
        "show.html"
        |> ProjectView.render(
          project: project,
          updates: @updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      refute output =~ "contact-element-contact"
    end

    test ".contact-element-email is not rendered if media_email is not available" do
      project = %{@project | contact_information: "present", media_phone: "present"}

      output =
        "show.html"
        |> ProjectView.render(
          project: project,
          updates: @updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      refute output =~ "contact-element-email"
    end

    test ".contact-element-phone is not rendered if media_phone is not available" do
      project = %{@project | contact_information: "present", media_email: "present"}

      output =
        "show.html"
        |> ProjectView.render(
          project: project,
          updates: @updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      refute output =~ "contact-element-phone"
    end

    test ".contact-element-contact is rendered if contact_information is available" do
      project = %{@project | contact_information: "present"}

      output =
        "show.html"
        |> ProjectView.render(
          project: project,
          updates: @updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      assert output =~ "contact-element-contact"
    end

    test ".contact-element-email is rendered if media_email is available" do
      project = %{@project | media_email: "present"}

      output =
        "show.html"
        |> ProjectView.render(
          project: project,
          updates: @updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      assert output =~ "contact-element-email"
    end

    test ".contact-element-phone is rendered if media_phone is available" do
      project = %{@project | media_phone: "present"}

      output =
        "show.html"
        |> ProjectView.render(
          project: project,
          updates: @updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      assert output =~ "contact-element-phone"
    end
  end

  describe "_updates.html" do
    test "renders project updates" do
      updates = @updates

      output =
        "show.html"
        |> ProjectView.render(
          project: @project,
          updates: updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      assert output =~ "c-project-updates-list"
      assert output =~ "c-project-update"
    end

    test "does not render an image if the update does not include one" do
      updates = @updates

      output =
        "show.html"
        |> ProjectView.render(
          project: @project,
          updates: updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      refute output =~ "c-project-update__photo"
    end

    test "renders an image if the update includes one" do
      updates = [
        %{
          List.first(@updates)
          | image: %Image{url: "http://example.com/img.jpg", alt: "Alt text"}
        }
      ]

      output =
        "show.html"
        |> ProjectView.render(
          project: @project,
          updates: updates,
          conn: @conn,
          upcoming_events: @events,
          past_events: @events
        )
        |> HTML.safe_to_string()

      assert output =~ "c-project-update__photo"
    end
  end
end
