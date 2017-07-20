defmodule Content.Paragraph do
  @moduledoc """

  This module represents the suite of paragraph types that we support on Drupal.
  To add a new Drupal paragraph type, say MyPara, that should show up on pages
  via Phoenix, make the following changes:

  * Pull the most recent content from the CMS. Locally, update the
    /cms/style-guide/paragraphs page, which demonstrates all our paragraphs,
    to include this new paragraph.
  * Load /cms/style-guide/paragraphs?_format=json from the CMS and update
    /cms/style-guide/paragraphs.json.
  * Create a new module, Content.Paragraph.MyPara in lib/paragraph/my_para.ex.
  * Add that type to Content.Paragraph.t here.
  * Update this module's from_api/1 function to dispatch to the MyPara.from_api
  * Update Site.ContentView.render_paragraph/1 to display it.
  * Update the Site.ContentControllerTest test for "renders a landing page with
    all its paragraphs" to include content from the paragraph put in
    cms/style-guide/paragraphs.json
  * Update Content.ParagraphTest to ensure it is parsed correctly
  * Update Site.ContentViewTest to ensure it is rendered correctly
  * After the code is merged and deployed, update /cms/style-guide/paragraphs
    on the live CMS
  """

  alias Content.Paragraph

  @type t :: Paragraph.CustomHTML.t | Paragraph.TitleCardSet.t |
             Paragraph.UpcomingBoardMeetings.t | Paragraph.PeopleGrid.t |
             Paragraph.FilesGrid.t

  @spec from_api(map) :: t
  def from_api(%{"type" => [%{"target_id" => "custom_html"}]} = para) do
    Paragraph.CustomHTML.from_api(para)
  end
  def from_api(%{"type" => [%{"target_id" => "title_card_set"}]} = para) do
    Paragraph.TitleCardSet.from_api(para)
  end
  def from_api(%{"type" => [%{"target_id" => "upcoming_board_meetings"}]} = para) do
    Paragraph.UpcomingBoardMeetings.from_api(para)
  end
  def from_api(%{"type" => [%{"target_id" => "people_grid"}]} = para) do
    Paragraph.PeopleGrid.from_api(para)
  end
  def from_api(%{"type" => [%{"target_id" => "files_grid"}]} = para) do
    Paragraph.FilesGrid.from_api(para)
  end
end
