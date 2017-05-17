defmodule Content.RepoTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "recent_news" do
    test "returns list of Content.NewsEntry" do
      [%Content.NewsEntry{
         body: body,
         media_contact_name: media_contact_name,
         featured_image: featured_image
       } | _] = Content.Repo.recent_news()

      assert safe_to_string(body) =~ "BOSTON -- The MBTA"
      assert media_contact_name == "MassDOT Press Office"
      assert featured_image.alt == "Commuter Rail Train"
      assert featured_image.url =~ "Allston%20train.jpg"
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

  describe "get_page/1" do
    test "returns a Content.BasicPage" do
      %Content.BasicPage{title: title, body: body} = Content.Repo.get_page("/accessibility")
      assert title == "Accessibility at the T"
      assert safe_to_string(body) =~ "From accessible buses, trains, and stations"
    end

    test "returns a Content.ProjectUpdate" do
      %Content.ProjectUpdate{
        body: body,
        featured_image: featured_image,
        photo_gallery: [photo_gallery_image | _] = photo_gallery
      } = Content.Repo.get_page("/gov-center-project")

      assert safe_to_string(body) =~ "Value Engineering (VE), managed by"
      assert featured_image.alt == "Proposed Government Center Head House"
      assert length(photo_gallery) == 2
      assert photo_gallery_image.alt == "Government Center during construction"
      assert photo_gallery_image.url =~ "Gov%20Center%20Photo%201%281%29.jpg"
    end

    test "returns nil if no such page" do
      assert nil == Content.Repo.get_page("/does/not/exist")
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
end
