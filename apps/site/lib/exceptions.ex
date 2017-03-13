defimpl Plug.Exception, for: Content.NoResultsError do
  def status(_exception), do: 404
end
