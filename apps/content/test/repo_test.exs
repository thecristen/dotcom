defmodule Content.RepoTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "recent_news" do
    test "returns list of Content.NewsEntry" do
      [%Content.NewsEntry{
         body: body,
         media_contact: media_contact
       } | _] = Content.Repo.recent_news()

      assert safe_to_string(body) =~ "BOSTON -- The MBTA"
      assert media_contact == "MassDOT Press Office"
    end

    test "allows the current News Entry to be excluded" do
      current_id = 1
      recent_news = Content.Repo.recent_news(current_id: current_id)

      recent_news_ids = Enum.map(recent_news, &(&1.id))
      refute Enum.member?(recent_news_ids, current_id)
    end
  end

  describe "news_entry!/1" do
    test "returns the news entry for the given id" do
      assert %Content.NewsEntry{
        id: 1
      } = Content.Repo.news_entry!("1")
    end

    test "raises Content.NoResultsError given an unknown id" do
      assert_raise Content.NoResultsError, fn ->
        Content.Repo.news_entry!("nonexistent")
      end
    end
  end

  describe "news_entry_by/1" do
    test "returns the news entry for the given id" do
      assert %Content.NewsEntry{id: 1} = Content.Repo.news_entry_by(id: "1")
    end

    test "returns nil given no record is found" do
      assert is_nil(Content.Repo.news_entry_by(id: "999"))
    end
  end

  describe "get_page/1" do
    test "given the path for a Basic page" do
      result = Content.Repo.get_page("/accessibility")
      assert %Content.BasicPage{} = result
    end

    test "given the path for a Landing page" do
      result = Content.Repo.get_page("/denali-national-park")
      assert %Content.LandingPage{} = result
    end

    test "given the path for a Redirect page" do
      result = Content.Repo.get_page("/test/redirect")
      assert %Content.Redirect{} = result
    end

    test "returns nil when the path does not match an existing page" do
      assert nil == Content.Repo.get_page("/does/not/exist")
    end

    test "URL encodes the query string before fetching" do
      assert %Content.Redirect{
        link: %Content.Field.Link{url: "http://google.com"}
      } = Content.Repo.get_page("/test/path", "id=5")
    end
  end

  describe "events/1" do
    test "returns list of Content.Event" do
      assert [%Content.Event{
        id: id,
        body: body
      } | _] = Content.Repo.events()

      assert id == 17
      assert safe_to_string(body) =~ "<p><strong>Massachusetts Department"
    end
  end

  describe "event!/1" do
    test "returns the event if it's present" do
      assert %Content.Event{
        id: 17
      } = Content.Repo.event!("17")
    end

    test "raises Content.NoResultsError if not present" do
      assert_raise Content.NoResultsError, fn ->
        Content.Repo.event!("nonexistent")
      end
    end
  end

  describe "event_by/1" do
    test "returns the event for the given id" do
      assert %Content.Event{id: 17} = Content.Repo.event_by(id: "17")
    end

    test "returns nil given no record is found" do
      assert is_nil(Content.Repo.event_by(id: "999"))
    end
  end

  describe "projects/1" do
    test "returns list of Content.Project" do
      assert [%Content.Project{
        id: id,
        body: body
      }, %Content.Project{} | _] = Content.Repo.projects()

      assert id == 2679
      assert safe_to_string(body) =~ "Ruggles Station Platform Project"
    end

    test "returns empty list if error" do
      assert [] = Content.Repo.projects(error: true)
    end
  end

  describe "project!/1" do
    test "returns a Content.Project" do
      assert %Content.Project{
        id: id,
        body: body
      } = Content.Repo.project!(2679)

      assert id == 2679
      assert safe_to_string(body) =~ "Ruggles Station Platform Project"
    end

    test "raises Content.NoResultsError if not present" do
      assert_raise Content.NoResultsError, fn ->
        Content.Repo.project!("nonexistent")
      end
    end
  end

  describe "project_updates/1" do
    test "returns a list of Content.ProjectUpdate" do
      assert [%Content.ProjectUpdate{body: body, id: id}] = Content.Repo.project_updates()
      assert id == 123
      assert safe_to_string(body) =~ "body"
    end

    test "returns empty list if error" do
      assert [] = Content.Repo.project_updates(error: true)
    end
  end

  describe "project_update!/1" do
    test "returns a Content.ProjectUpdate" do
      assert %Content.ProjectUpdate{body: body, id: id} = Content.Repo.project_update!(123)
      assert id == 123
      assert safe_to_string(body) =~ "body"
    end

    test "raises Content.NoResultsError if not present" do
      assert_raise Content.NoResultsError, fn ->
        Content.Repo.project_update!("nonexistent")
      end
    end
  end

  describe "person!/1" do
    test "returns the person if they're present" do
      assert %Content.Person{
        id: 2579
      } = Content.Repo.person!("2579")
    end

    test "raises Content.NoResultsError if not present" do
      assert_raise Content.NoResultsError, fn ->
        Content.Repo.person!("0")
      end
    end
  end

  describe "people/1" do
    test "returns a list of people if they're present" do
      assert [%Content.Person{id: 2579}, %Content.Person{id: 2581}] = Content.Repo.people()
    end
  end

  describe "whats_happening" do
    test "returns a list of Content.WhatsHappeningItem" do
      assert [%Content.WhatsHappeningItem{
        blurb: blurb
      } | _] = Content.Repo.whats_happening()

      assert blurb =~ "The Fiscal and Management Control Board"
    end
  end

  describe "important_notice" do
    test "returns a Content.ImportantNotice" do
      assert %Content.ImportantNotice{
        blurb: blurb
      } = Content.Repo.important_notice()

      assert blurb =~ "The Red Line north passageway at Downtown Crossing"
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
end
