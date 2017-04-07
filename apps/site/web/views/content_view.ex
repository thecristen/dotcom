defmodule Site.ContentView do
  use Site.Web, :view
  import Site.TimeHelpers
  import Site.ContentHelpers, only: [content: 1]
end
