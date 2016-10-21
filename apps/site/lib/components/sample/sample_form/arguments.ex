defmodule Site.Components.Sample.SampleForm do
  @moduledoc """

  This is a form. Lorem ipsum dolor sit amet, consectetur adipiscing
  elit. Fusce accumsan tellus rutrum enim semper, pulvinar hendrerit risus
  cursus. Vivamus ac eros luctus, fermentum dui vitae, malesuada nisl. Donec
  dictum dictum nunc, sit amet dignissim tortor. Pellentesque egestas varius
  augue ac pretium. Suspendisse quis elementum nisl, id convallis
  mauris. Duis iaculis nibh id arcu accumsan, sed condimentum lacus
  rutrum. Phasellus auctor, nisi at interdum ultricies, metus metus imperdiet
  neque, at ultricies dolor augue in ligula. Suspendisse eget metus ante. In
  eget porttitor libero. Curabitur quis arcu a felis bibendum rhoncus a ut
  arcu.

  """
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
