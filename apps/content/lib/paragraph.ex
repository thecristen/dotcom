defmodule Content.Paragraph do
  @moduledoc """

  This module represents the suite of paragraph types that we support on Drupal.
  To add a new Drupal paragraph type, say MyPara, that should show up on pages
  via Phoenix, make the following changes:

  * Create a new module, Content.Paragraph.MyPara in lib/paragraph/my_para.ex.
  * Add that type to Content.Paragraph.t here.
  * Update this module's from_api/1 function to dispatch to the MyPara.from_api
  * Update Site.ContentView.render_paragraph/1 to display it.
  * Hit the Drupal JSON api to determine what really comes over the wire and add
    it to the "field_paragraphs" bit of priv/accessibility/all-paragraphs.json.
  * Update the Site.ContentControllerTest test for "renders a basic page with
    all its paragraphs" to include content from the paragraph put in
    all-paragraphs.json
  * Update Content.ParagraphTest to ensure it is parsed correctly
  * Update Site.ContentViewTest to ensure it is rendered correctly
  """

  @type t :: Content.Paragraph.CustomHTML.t | Content.Paragraph.TitleCardSet.t

  @spec from_api(map) :: t
  def from_api(%{"type" => [%{"target_id" => "custom_html"}]} = para) do
    Content.Paragraph.CustomHTML.from_api(para)
  end
  def from_api(%{"type" => [%{"target_id" => "title_card_set"}]} = para) do
    Content.Paragraph.TitleCardSet.from_api(para)
  end
end
