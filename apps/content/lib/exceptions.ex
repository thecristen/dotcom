defmodule Content.NoResultsError do
  defexception [message: "Record Not Found"]
end

defmodule Content.ErrorFetchingContent do
  defexception [:message]

  def exception(opts) do
    message = Keyword.fetch!(opts, :message)

    %__MODULE__{message: "Error: `#{inspect message}`"}
  end
end
