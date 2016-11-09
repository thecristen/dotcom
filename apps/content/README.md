# Content

This wraps our Drupal installation, and handles the communication with the
installation.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `content` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:content, "~> 0.1.0"}]
    end
    ```

  2. Ensure `content` is started before your application:

    ```elixir
    def application do
      [applications: [:content]]
    end
    ```
