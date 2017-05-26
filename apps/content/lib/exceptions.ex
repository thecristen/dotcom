defmodule Content.NoResultsError do
  defexception [message: "Record Not Found"]
end

defmodule Content.MigrationError do
  defexception [:message]
end
