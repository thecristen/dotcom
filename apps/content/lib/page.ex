defmodule Content.Page do
  @moduledoc """

  A standalone page.

  """
  @type t :: %__MODULE__{
    type: String.t,
    title: String.t,
    body: String.t,
    updated_at: DateTime.t,
    fields: %{atom => any}
  }
  defstruct [
    type: {:missing, :type},
    title: {:missing, :title},
    body: {:missing, :body},
    updated_at: {:missing, :updated_at},
    fields: %{}
  ]

  def rewrite_static_files(%Content.Page{body: body} = page) when is_binary(body) do
    %{page | body: rewrite_static_files(body)}
  end
  def rewrite_static_files(%Content.Page{} = page), do: page
  def rewrite_static_files(body) when is_binary(body) do
    static_path = Content.Config.static_path
    Regex.replace(~r/"(#{static_path}[^"]+)"/, body, fn _, path ->
      ['"', Content.Config.apply(:static, [path]), '"']
    end)
  end
end

defmodule Content.Page.Image do
  @type t :: %__MODULE__{
    url: String.t,
    alt: String.t,
    width: non_neg_integer,
    height: non_neg_integer
  }

  defstruct [
    url: {:missing, :url},
    alt: {:missing, :alt},
    width: {:missing, :width},
    height: {:missing, :height}
  ]

  def rewrite_url(url, opts \\ []) when is_binary(url) do
    root = case opts[:root] || Content.Config.root do
             nil -> "missing-host-should-not-match"
             host -> String.replace_suffix(host, "/", "")
           end
    static_path = opts[:static_path] || Content.Config.static_path

    Regex.replace(~r/^#{root}(#{static_path}[^"]+)/, url, fn _, path ->
      Content.Config.apply(:static, [path])
    end)
  end
end
