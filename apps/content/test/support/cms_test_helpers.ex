defmodule Content.CMSTestHelpers do
  def update_api_response(api_response, field, value) do
    %{^field => [old_value]} = api_response
    %{api_response | field => [%{old_value | "value" => value}]}
  end

  def update_api_response_whole_field(api_response, field, value) do
    %{api_response | field => value}
  end
end
