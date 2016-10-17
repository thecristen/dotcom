defmodule Site.Components.Sample.SampleForm do
  defstruct class: "form",
            id: nil,
            action: "/sample",
            fields: [%{
              name: "Field 1",
              id: "field_1",
              required: false,
              type: "text",
              default_value: nil,
              placeholder: "Field 1"
            }, %{
              name: "Field 2",
              id: "field_2",
              required: false,
              type: "text",
              default_value: nil,
              placeholder: "Field 2"
            }],
            submit_text: "Submit Form"

end
