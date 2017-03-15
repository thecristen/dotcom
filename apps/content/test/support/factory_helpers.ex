defmodule Content.FactoryHelpers do
  def update_fields_attribute(page, key, value) do
    put_in(page.fields[key], value)
  end

  def update_attribute(page, key, value) do
    Map.put(page, key, value)
  end
end
