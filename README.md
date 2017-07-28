[![Build Status](https://semaphoreci.com/api/v1/projects/ed6a7697-4bde-446b-89bd-47c634431bf0/950162/badge.svg)](https://semaphoreci.com/mbta/dotcom)

# DotCom

The new face of http://mbta.com/

## Getting Started

1. Install Erlang/Elixir: http://elixir-lang.org/install.html
1. Install NodeJS: https://nodejs.org/en/download/
1. Install Sass:
  * `gem install sass`
  * You might get a permission error here.  You can either `sudo gem install
    sass`, or install a Ruby environment manager.
1. Install Phoenix: http://www.phoenixframework.org/docs/installation
1. Install our Elixir dependencies:
  * `mix deps.get`
1. Install our Node dependencies:
  * `npm run install`
  * If you run into an error about fetching a Github dependency, you can tell Git to always use HTTP for Github:

      git config --global url.https://github.com/.insteadOf git://github.com/
1. Run `npm run brunch:build`

## Running the Server

    mix phoenix.server

Then, visit the site at http://localhost:4001/

## Tests

Run `mix phoenix.server` to start a server in one window, then open a
separate window and run `npm test` from the main folder. This will execute
the following scripts in succession:

* `mix test` — Phoenix tests
* `npm run test:js` — JS tests
* `mix backstop.tests` — Backstop tests (see section below for details)

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

### Other helpful test scripts

All run from the main folder:

* `npm run backstop:reference` — create new backstop reference images
* `npm run backstop:bless` — allow backstop tests to run after changing the
  backstop.json file without creating new reference images
* `npm run brunch:build` — builds the static files
* `semaphore/smoke_test.sh` - tries to hit all the URLs on your server.
  Requires wget (installable with `brew install wget`)

### Pronto

Pronto is a lint runner for various languages.

Installing Pronto on Max OS can be challenging because some of its dependencies are missing or outdated.

Follow these instructions to install:

```
brew install cmake
brew install pkg-config
sudo gem install json -v 1.8
sudo gem install pronto
sudo gem install pronto-scss
sudo gem install pronto-eslint
sudo gem install pronto-credo
```

Run it by calling `pronto run` in the `mbta/dotcom` directory. If there is no output, that means it passed.

## Backstop Tests

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

To run the tests, use the following command:

```
mix backstop.tests
```

For more information about the initial setup, running the tests, and adding new ones please see this wiki [article](https://github.com/mbta/dotcom/wiki/BackstopJS-Tests).

## Environment Variables

The following variables can be used in your development environment.

* `GOOGLE_API_KEY` - You can get a key from [Google's API documentation](https://developers.google.com/maps/documentation/javascript/get-api-key).
This will ensure any javascript that uses Google's API will work correctly.
* `WIREMOCK_PATH` - The path to your wiremock `.jar` file. Currently, this optional variable is only used by `npm` tasks, and not `mix`. If it is not set, `bin/wiremock-standalone-2.1.10.jar` will be used as the default.
* `V3_URL` - you can use this to point at a local API (`http://localhost:4000`) or the production API (`https://api.mbtace.com`)

## Building

1. (once) Install Docker: https://docs.docker.com/engine/installation/
1. Build the .ZIP package:
  * `sh build.sh`

This will build the release in a Docker container, and put the files in
`site-build.zip`.  This file contains all of our code, an Erlang
distribution, and a Dockerfile to run the application.

The root `Dockerfile` is responsible the build. Because most of us develop on
a Mac but the servers are Linux, we need to run the build inside a Docker
container so that everything is compiled correctly. The build uses `exrm` to
make the Erlang release, along with all our dependencies. We then copy all
those files out of the Docker build container, .zip them up, and send them
along to Amazon.

The Dockerfile used to run the application lives in `rel/Dockerfile`. It runs
the script that `exrm` provides for us to run the server (
`/root/rel/site/bin/site foreground`). At startup, the `relx` application
looks for configuration values that look like `${VARIABLE}` and replaces them
with the `VARIABLE` environment variable. This allows us to make a single
build, but use it for different environments by changing the environment
variables.

## Deploying

The [deployment instructions](https://github.com/mbta/wiki/blob/master/website/operations.md#deployment) are in the wiki.

## Documentation

You can generate documentation for the project by running `$ mix docs` from the root directory.
You can then view the genereated documentation in the `doc/` directory
`$ open doc/index.html`


## Content

To set up the Drupal CMS and work on the content app, follow its [README](/blob/master/apps/content/README.md).
