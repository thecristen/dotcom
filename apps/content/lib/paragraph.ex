defmodule Content.Paragraph do
  @type t :: Content.Paragraph.CustomHTML.t | Content.Paragraph.TitleCardSet.t

  @spec try_from_api(map) :: [t]
  def try_from_api(%{"type" => [%{"target_id" => "custom_html"}]} = para) do
    [Content.Paragraph.CustomHTML.from_api(para)]
  end
  def try_from_api(%{"type" => [%{"target_id" => "title_card_set"}]} = para) do
    [Content.Paragraph.TitleCardSet.from_api(para)]
  end
  def try_from_api(_) do
    []
  end
end
