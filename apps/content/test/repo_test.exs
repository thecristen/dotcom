defmodule Content.RepoTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "recent_news" do
    test "returns list of Content.NewsEntry" do
      [%Content.NewsEntry{
         body: body,
         media_contact: media_contact
       } | _] = Content.Repo.recent_news()

      assert safe_to_string(body) =~ "<p>Beginning Sunday, April 1, the MBTA will begin a one-year"
      assert media_contact == "MassDOT Press Office"
    end

    test "allows the current News Entry to be excluded" do
      current_id = 3519
      recent_news = Content.Repo.recent_news(current_id: current_id)

      recent_news_ids = Enum.map(recent_news, &(&1.id))
      refute Enum.member?(recent_news_ids, current_id)
    end
  end

  describe "news_entry_by/1" do
    test "returns the news entry for the given id" do
      assert %Content.NewsEntry{id: 3519} = Content.Repo.news_entry_by(id: 3519)
    end

    test "returns :not_found given no record is found" do
      assert :not_found == Content.Repo.news_entry_by(id: 999)
    end
  end

  describe "get_page/1" do
    test "given the path for a Basic page" do
      result = Content.Repo.get_page("/basic_page_with_sidebar")
      assert %Content.BasicPage{} = result
    end

    test "returns a NewsEntry" do
      assert %Content.NewsEntry{} = Content.Repo.get_page("/news/2018/news-entry")
    end

    test "returns an Event" do
      assert %Content.Event{} = Content.Repo.get_page("/events/date/title")
    end

    test "returns a Project" do
      assert %Content.Project{} = Content.Repo.get_page("/projects/project-name")
    end

    test "returns a ProjectUpdate" do
      assert %Content.ProjectUpdate{} = Content.Repo.get_page("/projects/project-name/update/project-progress")
    end

    test "given the path for a Basic page with tracking params" do
      result = Content.Repo.get_page("/basic_page_with_sidebar", %{"from" => "search"})
      assert %Content.BasicPage{} = result
    end

    test "given the path for a Landing page" do
      result = Content.Repo.get_page("/landing_page")
      assert %Content.LandingPage{} = result
    end

    test "given the path for a Redirect page" do
      result = Content.Repo.get_page("/redirect_node")
      assert %Content.Redirect{} = result
    end

    test "returns {:error, :not_found} when the path does not match an existing page" do
      assert Content.Repo.get_page("/does/not/exist") == {:error, :not_found}
    end

    test "returns {:error, :invalid_response} when the CMS returns a server error" do
      assert Content.Repo.get_page("/cms/route-pdfs/error") == {:error, :invalid_response}
    end

    test "returns {:error, :invalid_response} when JSON is invalid" do
      assert Content.Repo.get_page("/invalid") == {:error, :invalid_response}
    end

    test "given special preview query params, return certain revision of node" do
      result = Content.Repo.get_page("/basic_page_no_sidebar", %{"preview" => "", "vid" => "112", "nid" => "6"})
      assert %Content.BasicPage{} = result
      assert result.title == "Arts on the T 112"
    end
  end

  describe "get_page_with_encoded_id/2" do
    test "encodes the id param into the request" do
      assert Content.Repo.get_page("/redirect_node_with_query", %{"id" => "5"}) == {:error, :not_found}
      assert %Content.Redirect{} =
        Content.Repo.get_page_with_encoded_id("/redirect_node_with_query", %{"id" => "5"})
    end
  end

  describe "events/1" do
    test "returns list of Content.Event" do
      assert [%Content.Event{
        id: id,
        body: body
      } | _] = Content.Repo.events()

      assert id == 3268
      assert safe_to_string(body) =~ "(FMCB) closely monitors the T’s finances, management, and operations.</p>"
    end
  end

  describe "event_by/1" do
    test "returns the event for the given id" do
      assert %Content.Event{id: 3268} = Content.Repo.event_by(id: 3268)
    end

    test "returns :not_found given no record is found" do
      assert :not_found == Content.Repo.event_by(id: 999)
    end
  end

  describe "projects/1" do
    test "returns list of Content.Project" do
      assert [%Content.Project{
        id: id,
        body: body
      }, %Content.Project{} | _] = Content.Repo.projects()

      assert id == 3004
      assert safe_to_string(body) =~ "Wollaston Station Improvements"
    end

    test "returns empty list if error" do
      assert [] = Content.Repo.projects(error: true)
    end
  end

  describe "project_updates/1" do
    test "returns a list of Content.ProjectUpdate" do
      assert [%Content.ProjectUpdate{body: body, id: id},
              %Content.ProjectUpdate{body: body_2, id: id_2} | _] = Content.Repo.project_updates()
      assert id == 3005
      assert id_2 == 3174
      assert safe_to_string(body) =~ "What's the bus shuttle schedule?"
      assert safe_to_string(body_2) =~ "Wollaston Station on the Red Line closed for renovation"
    end

    test "returns empty list if error" do
      assert [] = Content.Repo.project_updates(error: true)
    end
  end

  describe "whats_happening" do
    test "returns a list of Content.WhatsHappeningItem" do
      assert [%Content.WhatsHappeningItem{
        blurb: blurb
      } | _] = Content.Repo.whats_happening()

      assert blurb =~ "Bus shuttles replace Commuter Rail service on the Franklin Line"
    end
  end

  describe "important_notice" do
    test "returns a Content.ImportantNotice" do
      assert %Content.ImportantNotice{
        blurb: blurb
      } = Content.Repo.important_notice()

      assert blurb == "Watch a live stream of today's FMCB meeting at 12PM."
    end
  end

  describe "search" do
    test "with results" do
      {:ok, result} = Content.Repo.search("mbta", 0, [])
      assert result.count == 2083
    end

    test "without results" do
      {:ok, result} = Content.Repo.search("empty", 0, [])
      assert result.count == 0
    end
  end

  describe "get_route_pdfs/1" do
    test "returns list of RoutePdfs" do
      assert [%Content.RoutePdf{}, _, _] = Content.Repo.get_route_pdfs("87")
    end

    test "returns empty list if there's an error" do
      log = ExUnit.CaptureLog.capture_log(fn ->
        assert [] = Content.Repo.get_route_pdfs("error")
      end)
      assert log =~ "Error getting pdfs"
    end

    test "returns empty list if there's no pdfs for the route id" do
      assert [] = Content.Repo.get_route_pdfs("doesntexist")
    end
  end
end
