[![Build Status](https://semaphoreci.com/api/v1/projects/ed6a7697-4bde-446b-89bd-47c634431bf0/950162/badge.svg)](https://semaphoreci.com/mbta/dotcom)

# DotCom

The new face of https://www.mbta.com/

## Getting Started

1. Request V3 API key at https://dev.api.mbtace.com/

1. Install [Homebrew](https://docs.brew.sh/Installation.html):
    ```
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    ```

1. Install [asdf package version manager](https://github.com/asdf-vm/asdf)
   * Follow the instructions on https://github.com/asdf-vm/asdf
   * Install the necessary tools to set up asdf plugins:

     ```
     brew install coreutils automake autoconf openssl libyaml readline libxslt libtool unixodbc
     brew cask install java
     ```

   * Add asdf plugins

     ```
     asdf plugin-add erlang
     asdf plugin-add elixir
     asdf plugin-add ruby
     asdf plugin-add nodejs
     ```

   * Import the Node.js release team's OpenPGP keys to install 'nodejs' plugin:

     ```
     bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
     ```

     If you run into problems, you might have to update the `import-release-team-keyring` script as described in this [wiki article](https://github.com/mbta/wiki/blob/master/website/asdf-nodejs.md)

   * Run the install:

     ```
     asdf install
     ```

   * Verify that all the plugins got installed:

     ```
     asdf plugin-list
     ```

     You should see the following output:

     ```
     elixir
     erlang
     nodejs
     ruby
     ```

1. Install Sass:
    ```
    gem install sass
    ```

1. Install chromedriver (for Elixir acceptance tests using Wallaby)
    ```
    brew tap caskroom/cask
    brew cask install chromedriver
    ```

1. Install our Elixir dependencies. From the root of this repo:
    ```
    mix deps.get
    ```

1. Install npm globally
   ```
   npm install -g npm@6.7.0
   ```

1. Install our Node dependencies. From the root of this repo:
    ```
    npm run install
    ```
   If you run into an error about fetching a Github dependency, you can tell Git to always use HTTP for Github:
    ```
    git config --global url.https://github.com/.insteadOf git://github.com/
    ```

1. Setup React:
    ```
    npm run react:setup && npm run react:build
    ```

1. Build the assets:
    ```
    npm run webpack:build
    ```

1. Set up the following environment variables (see [Environment Variables](#environment-variables) section):
  * `V3_API_KEY`
  * `GOOGLE_API_KEY`
  * `DRUPAL_ROOT`
  * `ALGOLIA_APP_ID`
  * `ALGOLIA_ADMIN_KEY`
  * `ALGOLIA_SEARCH_KEY`

## Running the Server

Start the server with `mix phx.server`

Then, visit the site at http://localhost:4001/

## Tests

Run `mix phx.server` to start a server in one window, then open a
separate window and run `npm test` from the main folder. This will execute
the following scripts in succession:

* `mix test` — Phoenix tests
* `npm run test:js` — JS tests
* `npm run backstop` — Backstop tests (see section below for details)

Note that all tests will run even if one of them fails, and there is no final
summary at the end, so pay attention to the output while they're running to
make sure everything passes.

### Dialyzer

Dialyzer is a static analysis tool which looks at type information. We use it
verify our type specifcations and make sure we're calling functions properly.

* `mix dialyzer` — Runs the actual type checks.

Currently, there are some spurious "The variable _ can never match ..."
errors that can be ignored.
`npm run dialyzer` will filter out these errors, though there are still a few
which show up.

### Pronto

Pronto is a lint runner for various languages.

Installing Pronto on Max OS can be challenging because some of its dependencies are missing or outdated.

Follow these instructions to install:

```
brew install cmake
brew install pkg-config
gem install pronto
gem install pronto-scss
gem install pronto-credo
```

Run it by calling `pronto run` in the `mbta/dotcom` directory. If there is no output, that means it passed.

### Javascript and Typescript formatting

Our javascript is linted by eslint and formatted by prettier. At this time, only prettier formatting is enforced in CI for javascript. For Typescript, both eslint and prettier are enforced in CI. You can auto-format your javascript and Typescript via `npm run format`, or set it up to autoformat on save in your editor of choice.

If you are using the Prettier plugin for Visual Studio Code, you will want to configure it to use the ignore file  in `apps/site/assets/.prettierignore`. 

### Backstop Tests

We use [BackstopJS](https://github.com/garris/BackstopJS) to test for
unexpected visual changes. Backstop works by keeping a repository of
reference images. When you run a backstop test it takes snapshots of the
pages on your localhost and compares them to those references images.
If anything has changed then the test will fail. This helps us catch unintended
changes to the UI (for example a CSS selector that is broader than
expected). Whenever you make a change that affects the UI, you will need to check
and if necessary update the backstop images.

The tests are run against a live application, built in production mode. To make sure that the tests
work consistently and do not depend on a specific schedule or realtime vehicle locations, we use
[WireMock](http://wiremock.org/) to record and playback the V3 API responses.

To run the tests, do the following:

* Make sure docker is [installed](https://docs.docker.com/docker-for-mac/install/) and running: we run the tests in docker to ensure we get consistent images across platforms.
* Run `npm run backstop` which starts up wiremock, a mocked phoenix server, and when those are up, kicks off backstop testing in docker

Note: If you are not running on OSX or Windows, you'll need to modify the `STATIC_HOST=host.docker.internal` in the commands.

For more information about the initial setup, running the tests, and adding new ones please see this wiki [article](https://github.com/mbta/wiki/blob/master/website/testing/backstop.md).

### Other helpful test scripts

All run from the main folder:

* `mix backstop.update` - takes any failed backstop diffs and marks them as new reference images
* `npm run backstop:reference` — create new backstop reference images
* `npm run webpack:watch` — run webpack-dev-server for local development
* `npm run webpack:build` — builds the static files for production
* `semaphore/smoke_test.sh` - tries to hit all the URLs on your server.
  Requires wget (installable with `brew install wget`)
* `mix run apps/content/bin/validate_fixtures.exs` - compares the attributes in our fixture files to production Drupal API endpoints to see if any are missing. Note that rather than using this script, it is better to update these fixture attributes at the time you are making API changes.


## Environment Variables

The following variables are used in your development environment:

### `V3_API_KEY`

You need to obtain and use an API key to run the website.
To request the key, use the [Development V3 API Portal](https://dev.api.mbtace.com/)

### `GOOGLE_API_KEY`

This will ensure any part of the site that uses Google's API will not get rate limited. See below for how to get a Google API Key.

1. Obtain a Google API key:
    * Go to [Google's API documentation](https://developers.google.com/maps/documentation/javascript/get-api-key)
    * Click on "GET STARTED", create a personal project (e.g. "mbtadotcom"). 
        * You have to enter personal billing information for your API key but Google gives you $200 of free credit per month. You can set up budget alerts to email you if you are approaching your free credit limit or set up daily quotas for each API. However, our costs accumulate very slowly in local development so it's not likely that you will approach this limit.
    * Go to [the Google developer credentials page](https://console.developers.google.com/apis/credentials)
    * Use the "Select Project" button at the top of the page to choose your project and then hit "Create Credentials" -> "API Key"
2. Enable specific APIs:
    * Go to the API library for your project (e.g. https://console.developers.google.com/apis/library?project=mbtadotcom)
    * Using the search box at the top of the page, find "Google Maps Geolocation API"
    * Click "Enable"
    * Repeat for
        * "Places API"
        * "Maps Javascript API"
        * "Maps Static API"

### `DRUPAL_ROOT`

This is the url for the CMS. You'll need to set this to view any of the static content on the site.

Unless you are working on some CMS-related feature, you should set it to:
    ```
    https://live-mbta.pantheonsite.io
    ```

Otherwise you can set it one of the following possible values:

* `https://test-mbta.pantheonsite.io` The staging server for the content.
* `https://dev-mbta.pantheonsite.io` The sandbox CMS server. Code changes for the CMS are sometimes deployed here to test them without disturbing the content writers' workflow.
* `http://mbta.kbox.site` Your local CMS server, if you are running it. Instructions for setting it up are in the [Content README](/apps/content/README.md).
* None, if you don't want any connection to a CMS.

Since different tasks require different servers, there's a script to quickly switch between different them in [the wiki](https://github.com/mbta/wiki/blob/master/website/development/tips-and-tricks.md#quickly-switching-between-cms-servers)

### `ALGOLIA_APP_ID`, `ALGOLIA_SEARCH_KEY`, and `ALGOLIA_ADMIN_KEY`

These keys are used to interact with the Algolia search api. The values can be found under the `Api Keys` section in Algolia (you'll need to be added as a team member to get access).

`ALGOLIA_APP_ID` is the id of the Algolia account that holds all of our search indexes
`ALGOLIA_ADMIN_KEY` allows write access and is used by the Algolia app to keep our search indexes updated
`ALGOLIA_SEARCH_KEY` is a read-only key that is used by the Site app to perform searches from the front-end

### `V3_URL`

This variable is used if you want to use a different API V3 server. You can use this to point at:
* `https://dev.api.mbtace.com`, the development API server. This is the recommended option, and it's also the default if the environment variable isn't set.
* `http://green.dev.api.mbtace.com`, the green.dev server (Note: http, not https).
* `https://api.mbtace.com`, the production server.
* `http://localhost:4000`, if you're running [the api server](https://github.com/mbta/api) locally.

Please note that you'll need a different API V3 key when working with different API servers.

### `STATIC_HOST`

To make your local server externally visible (useful for testing on a real phone, for example), set this to your IP address, which you can find from `ifconfig`, probably under `en0`.

### `WIREMOCK_PATH`

The path to your wiremock `.jar` file. Currently, this optional variable is only used by `npm` tasks, and not `mix`. If it is not set, `bin/wiremock-standalone-2.1.14.jar` will be used as the default. Ssee this wiki [article](https://github.com/mbta/wiki/blob/master/website/testing/backstop.md) for details.


### Making the variables available to the app

There are different ways to make sure these variables are in the environment when the application runs:

* Run the server with `env VARIABLE1=value2 VARIABLE2=value2 mix phx.server`. You may want to store them in a file (one per line) and run ```env `cat file_where_you_stored_the_variables` mix phx.server``` instead.
* Put the line `export VARIABLE=value` somewhere in your `.bash_profile`. Then run the application as normal with `mix phx.server`. Note that this environment variable will be available to anything you run in the terminal now, and if you host your config files publicly on github then you should be careful to not let your API key be publicly visible.

## Documentation

You can generate documentation for the project by running `$ mix docs` from the root directory.
You can then view the generated documentation in the `doc/` directory with `open doc/index.html`

## Content

To set up the Drupal CMS and work on the content app, follow its [README](/apps/content/README.md). You will need to set up the `DRUPAL_ROOT` environment variable as described above.

## Building the distribution package

1. (once) Install Docker: https://docs.docker.com/engine/installation/
1. Build the .ZIP package:
  * `sh build.sh`

This will build the release in a Docker container, and put the files in `site-build.zip`.  This file contains all of our code, an Erlang distribution, and a Dockerfile to run the application.

The root `Dockerfile` is responsible the build. Because most of us develop on a Mac but the servers are Linux, we need to run the build inside a Docker container so that everything is compiled correctly. The build uses `distillery` to make the Erlang release, along with all our dependencies. We then copy all those files out of the Docker build container, .zip them up, and send them along to Amazon.

The Dockerfile used to run the application lives in `rel/Dockerfile`. It runs the script that `exrm` provides for us to run the server (`/root/rel/site/bin/site foreground`). At startup, the `relx` application looks for configuration values that look like `${VARIABLE}` and replaces them with the `VARIABLE` environment variable. This allows us to make a single build, but use it for different environments by changing the environment variables.

## Deploying

The [operations instructions](https://github.com/mbta/wiki/blob/master/website/operations.md#deployment) are in the wiki.
