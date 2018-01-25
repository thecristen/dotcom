[![Build Status](https://semaphoreci.com/api/v1/projects/ed6a7697-4bde-446b-89bd-47c634431bf0/950162/badge.svg)](https://semaphoreci.com/mbta/dotcom)

# DotCom

The new face of https://www.mbta.com/

## Getting Started

1. Install [Homebrew](https://docs.brew.sh/Installation.html): 
```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

2. Install [Erlang/Elixir](http://elixir-lang.org/install.html): 
```
brew install elixir
``` 

3. Install NodeJS, version 8. If you don't need any other versions of node installed, install with:
```
brew install node@8 && brew link node@8 --force
``` 
Check that the correct version is installed with `node --version`

4. Install Sass:
```
gem install sass
```
You might get a permission error here.  You can either `sudo gem install sass`, or install a Ruby environment manager.

5. Install our Elixir dependencies: From the root of this repo:
```
mix deps.get
```

6. Install our Node dependencies: From the root of this repo: 
```
npm run install
```
If you run into an error about fetching a Github dependency, you can tell Git to always use HTTP for Github: 
```
git config --global url.https://github.com/.insteadOf git://github.com/
````

7. Run 
```
npm run brunch:build
```

## Running the Server

Start the server with `mix phx.server`

Then, visit the site at http://localhost:4001/

## Tests

Run `mix phx.server` to start a server in one window, then open a
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

For more information about the initial setup, running the tests, and adding new ones please see this wiki [article](https://github.com/mbta/wiki/blob/master/website/testing/backstop.md).

## Environment Variables

The following variables can be used in your development environment.

### `GOOGLE_API_KEY`

This will ensure any part of the site that uses Google's API will not get rate limited. See below for how to get a Google API Key. You can get a key from [Google's API documentation](https://developers.google.com/maps/documentation/javascript/get-api-key).

1. Click on "Get a Key", create a project (e.g. "mbtadotcom") and click "Enable API".
1. Go to the API library for your project (e.g. https://console.developers.google.com/apis/library?project=mbtadotcom)
1. Look for the Google Maps APIs list, expand "More"
1. Click on "Geolocation API" and
1. Click "Enable"
1. Depending on what you're working on, you may need to enable other APIs (several of them are enabled by default).

### `DRUPAL_ROOT`

The url for the CMS. You'll need to set this to view any of the static content on the site. Possible values are

* `http://test-mbta.pantheonsite.io` The staging server for the content. This will include changes to the content as they happen.
* `http://dev-mbta.pantheonsite.io` The sandbox CMS server. Code changes for the CMS are sometimes deployed here to test them without disturbing the content writers' workflow.
* `http://mbta.kbox.site` Your local CMS server, if you are running it. Instructions for setting it up are in the [Content README](/apps/content/README.md).
* None, if you don't want any connection to a CMS.

Since different tasks require different servers, there's a script to quickly switch between different them in [the wiki](https://github.com/mbta/wiki/blob/master/website/development/tips-and-tricks.md#quickly-switching-between-cms-servers)

### `WIREMOCK_PATH`

The path to your wiremock `.jar` file. Currently, this optional variable is only used by `npm` tasks, and not `mix`. If it is not set, `bin/wiremock-standalone-2.1.10.jar` will be used as the default.

### `V3_URL`

You can use this to point at
* `https://dev.api.mbtace.com`, the development api server. This is the recommended option, and the default if the environment variable isn't set.
* `https://api.mbtace.com`, the production server.
* `http://localhost:4000`, if you're running [the api server](https://github.com/mbta/api) locally.

### `STATIC_HOST`

To make your local server externally visible (useful for testing on a real phone, for example), set this to your IP address, which you can find from `ifconfig`, probably under `en0`.

### Making the variables available to the app.

There are two ways to make sure these environment variables are in the environment when the app runs.

* Run the server with `env VARIABLE1=value2 VARIABLE2=value2 mix phx.server`. You may want to store them in a file (one per line) and run ```env `cat file_where_you_stored_the_variables` mix phx.server``` instead.
* Put the line `export VARIABLE=value` somewhere in your `.bash_profile`. Then run the application as normal with `mix phx.server`. Note that this environment variable will be available to anything you run in the terminal now, and if you host your config files publicly on github then you should be careful to not let your API key be publicly visible.

## Documentation

You can generate documentation for the project by running `$ mix docs` from the root directory.
You can then view the genereated documentation in the `doc/` directory
`$ open doc/index.html`

## Content

To set up the Drupal CMS and work on the content app, follow its [README](/apps/content/README.md). You will need to set up the `DRUPAL_ROOT` environment variable as described above.

## Building

1. (once) Install Docker: https://docs.docker.com/engine/installation/
1. Build the .ZIP package:
  * `sh build.sh`

This will build the release in a Docker container, and put the files in `site-build.zip`.  This file contains all of our code, an Erlang distribution, and a Dockerfile to run the application.

The root `Dockerfile` is responsible the build. Because most of us develop on a Mac but the servers are Linux, we need to run the build inside a Docker container so that everything is compiled correctly. The build uses `distillery` to make the Erlang release, along with all our dependencies. We then copy all those files out of the Docker build container, .zip them up, and send them along to Amazon.

The Dockerfile used to run the application lives in `rel/Dockerfile`. It runs the script that `exrm` provides for us to run the server (`/root/rel/site/bin/site foreground`). At startup, the `relx` application looks for configuration values that look like `${VARIABLE}` and replaces them with the `VARIABLE` environment variable. This allows us to make a single build, but use it for different environments by changing the environment variables.

##Deploying

The [operations instructions](https://github.com/mbta/wiki/blob/master/website/operations.md#deployment) are in the wiki.
