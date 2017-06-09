defmodule Content.Paragraph.TitleCardSet do
  defstruct [title_cards: []]

  @type t :: %__MODULE__{
    title_cards: [Content.Paragraph.TitleCard.t]
  }

  @spec from_api(map) :: t
  def from_api(data) do
    cards =
      data
      |> Map.get("field_title_cards", [])
      |> Enum.map(&Content.Paragraph.TitleCard.from_api/1)

    %__MODULE__{
      title_cards: cards
    }
  end
end
