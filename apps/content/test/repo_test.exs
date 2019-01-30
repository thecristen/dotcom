defmodule Content.RepoTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML, only: [safe_to_string: 1]
  alias Content.Repo

  describe "recent_news" do
    test "returns list of Content.NewsEntry" do
      [
        %Content.NewsEntry{
          body: body,
          media_contact: media_contact
        }
        | _
      ] = Repo.recent_news()

      assert safe_to_string(body) =~
               "<p>Beginning Sunday, April 1, the MBTA will begin a one-year"

      assert media_contact == "MassDOT Press Office"
    end

    test "allows the current News Entry to be excluded" do
      current_id = 3519
      recent_news = Repo.recent_news(current_id: current_id)

      recent_news_ids = Enum.map(recent_news, & &1.id)
      refute Enum.member?(recent_news_ids, current_id)
    end
  end

  describe "news_entry_by/1" do
    test "returns the news entry for the given id" do
      assert %Content.NewsEntry{id: 3519} = Repo.news_entry_by(id: 3519)
    end

    test "returns :not_found given no record is found" do
      assert :not_found == Repo.news_entry_by(id: 999)
    end
  end

  describe "get_page/1" do
    test "given the path for a Basic page" do
      result = Repo.get_page("/basic_page_with_sidebar")
      assert %Content.BasicPage{} = result
    end

    test "returns a NewsEntry" do
      assert %Content.NewsEntry{} = Repo.get_page("/news/2018/news-entry")
    end

    test "returns an Event" do
      assert %Content.Event{} = Repo.get_page("/events/date/title")
    end

    test "returns a Project" do
      assert %Content.Project{} = Repo.get_page("/projects/project-name")
    end

    test "returns a ProjectUpdate" do
      assert %Content.ProjectUpdate{} =
               Repo.get_page("/projects/project-name/update/project-progress")
    end

    test "given the path for a Basic page with tracking params" do
      result = Repo.get_page("/basic_page_with_sidebar", %{"from" => "search"})
      assert %Content.BasicPage{} = result
    end

    test "given the path for a Landing page" do
      result = Repo.get_page("/landing_page")
      assert %Content.LandingPage{} = result
    end

    test "given the path for a Redirect page" do
      result = Repo.get_page("/redirect_node")
      assert %Content.Redirect{} = result
    end

    test "returns {:error, :not_found} when the path does not match an existing page" do
      assert Repo.get_page("/does/not/exist") == {:error, :not_found}
    end

    test "returns {:error, :invalid_response} when the CMS returns a server error" do
      assert Repo.get_page("/cms/route-pdfs/error") == {:error, :invalid_response}
    end

    test "returns {:error, :invalid_response} when JSON is invalid" do
      assert Repo.get_page("/invalid") == {:error, :invalid_response}
    end

    test "given special preview query params, return certain revision of node" do
      result =
        Repo.get_page("/basic_page_no_sidebar", %{"preview" => "", "vid" => "112", "nid" => "6"})

      assert %Content.BasicPage{} = result
      assert result.title == "Arts on the T 112"
    end

    test "deprecated use of 'latest' value for revision parameter still returns newest revision" do
      result =
        Repo.get_page("/basic_page_no_sidebar", %{
          "preview" => "",
          "vid" => "latest",
          "nid" => "6"
        })

      assert %Content.BasicPage{} = result
      assert result.title == "Arts on the T 113"
    end
  end

  describe "get_page_with_encoded_id/2" do
    test "encodes the id param into the request" do
      assert Repo.get_page("/redirect_node_with_query", %{"id" => "5"}) == {:error, :not_found}

      assert %Content.Redirect{} =
               Repo.get_page_with_encoded_id("/redirect_node_with_query", %{"id" => "5"})
    end
  end

  describe "events/1" do
    test "returns list of Content.Event" do
      assert [
               %Content.Event{
                 id: id,
                 body: body
               }
               | _
             ] = Repo.events()

      assert id == 3268

      assert safe_to_string(body) =~
               "(FMCB) closely monitors the T’s finances, management, and operations.</p>"
    end
  end

  describe "event_by/1" do
    test "returns the event for the given id" do
      assert %Content.Event{id: 3268} = Repo.event_by(id: 3268)
    end

    test "returns :not_found given no record is found" do
      assert :not_found == Repo.event_by(id: 999)
    end
  end

  describe "projects/1" do
    test "returns list of Content.Project" do
      assert [
               %Content.Project{
                 id: id,
                 body: body
               },
               %Content.Project{} | _
             ] = Repo.projects()

      assert id == 3004
      assert safe_to_string(body) =~ "Wollaston Station Improvements"
    end

    test "returns empty list if error" do
      assert [] = Repo.projects(error: true)
    end
  end

  describe "project_updates/1" do
    test "returns a list of Content.ProjectUpdate" do
      assert [
               %Content.ProjectUpdate{body: body, id: id},
               %Content.ProjectUpdate{body: body_2, id: id_2} | _
             ] = Repo.project_updates()

      assert id == 3005
      assert id_2 == 3174
      assert safe_to_string(body) =~ "What's the bus shuttle schedule?"
      assert safe_to_string(body_2) =~ "Wollaston Station on the Red Line closed for renovation"
    end

    test "returns empty list if error" do
      assert [] = Repo.project_updates(error: true)
    end
  end

  describe "whats_happening" do
    test "returns a list of Content.WhatsHappeningItem" do
      assert [
               %Content.WhatsHappeningItem{
                 blurb: blurb
               }
               | _
             ] = Repo.whats_happening()

      assert blurb =~
               "Visiting Boston? Find your way around with our new Visitor's Guide to the T."
    end
  end

  describe "banner" do
    test "returns a Content.Banner" do
      assert %Content.Banner{
               blurb: blurb
             } = Repo.banner()

      assert blurb == "Headline goes here"
    end
  end

  describe "search" do
    test "with results" do
      {:ok, result} = Repo.search("mbta", 0, [])
      assert result.count == 2083
    end

    test "without results" do
      {:ok, result} = Repo.search("empty", 0, [])
      assert result.count == 0
    end
  end

  describe "get_route_pdfs/1" do
    test "returns list of RoutePdfs" do
      assert [%Content.RoutePdf{}, _, _] = Repo.get_route_pdfs("87")
    end

    test "returns empty list if there's an error" do
      log =
        ExUnit.CaptureLog.capture_log(fn ->
          assert [] = Repo.get_route_pdfs("error")
        end)

      assert log =~ "Error getting pdfs"
    end

    test "returns empty list if there's no pdfs for the route id" do
      assert [] = Repo.get_route_pdfs("doesntexist")
    end
  end

  describe "teasers/1" do
    test "returns only teasers for a project type" do
      types =
        [type: "project"]
        |> Repo.teasers()
        |> MapSet.new(& &1.type)
        |> MapSet.to_list()

      assert types == [:project]
    end

    test "returns all teasers for a type that are sticky" do
      teasers =
        [type: "project", sticky: 1]
        |> Repo.teasers()

      assert [%Content.Teaser{}, %Content.Teaser{}, %Content.Teaser{}] = teasers
    end

    test "returns all teasers for a route" do
      types =
        [route_id: "Red", sidebar: 1]
        |> Repo.teasers()
        |> MapSet.new(& &1.type)
        |> MapSet.to_list()

      assert types == [:event, :news_entry, :project]
    end

    test "returns all teasers for a topic" do
      types =
        [topic: "Guides", sidebar: 1]
        |> Repo.teasers()
        |> MapSet.new(& &1.type)
        |> MapSet.to_list()

      assert types == [:event, :news_entry, :project]
    end

    test "returns all teasers for a mode" do
      types =
        [mode: "subway", sidebar: 1]
        |> Repo.teasers()
        |> MapSet.new(& &1.type)
        |> MapSet.to_list()

      assert types == [:event, :news_entry, :project]
    end

    test "returns all teasers for a mode and topic combined" do
      types =
        [mode: "subway", topic: "Guides", sidebar: 1]
        |> Repo.teasers()
        |> MapSet.new(& &1.type)
        |> MapSet.to_list()

      assert types == [:event, :news_entry, :project]
    end

    test "returns all teasers for a route_id and topic combined" do
      types =
        [route_id: "Red", topic: "Guides", sidebar: 1]
        |> Repo.teasers()
        |> MapSet.new(& &1.type)
        |> MapSet.to_list()

      assert types == [:event, :news_entry, :project]
    end

    test "takes a :type option" do
      teasers = Repo.teasers(route_id: "Red", type: :project, sidebar: 1)
      assert Enum.all?(teasers, &(&1.type == :project))
    end

    test "takes a :type_op option" do
      all_teasers = Repo.teasers(route_id: "Red", sidebar: 1)
      assert Enum.any?(all_teasers, &(&1.type == :project))

      filtered = Repo.teasers(route_id: "Red", type: :project, type_op: "not in", sidebar: 1)
      refute Enum.empty?(filtered)
      refute Enum.any?(filtered, &(&1.type == :project))
    end

    test "takes an :items_per_page option" do
      all_teasers = Repo.teasers(route_id: "Red", sidebar: 1)
      assert Enum.count(all_teasers) > 1
      assert [%Content.Teaser{}] = Repo.teasers(route_id: "Red", items_per_page: 1)
    end

    test "returns an empty list and logs a warning if there is an error" do
      log =
        ExUnit.CaptureLog.capture_log(fn ->
          assert Repo.teasers(route_id: "NotFound", sidebar: 1) == []
        end)

      assert log =~ "error=:not_found"
    end
  end
end
