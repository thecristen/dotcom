defmodule Algolia.MissingAppIdError do
  defexception [message: "ALGOLIA_APP_ID environment variable not defined"]
end

defmodule Algolia.MissingAdminKeyError do
  defexception [message: "ALGOLIA_ADMIN_KEY environment variable not defined"]
end

defmodule Algolia.MissingSearchKeyError do
  defexception [message: "ALGOLIA_SEARCH_KEY environment variable not defined"]
end
