[![Build Status](https://semaphoreci.com/api/v1/projects/3e8894ff-9143-4cb0-a0ae-a4489ca741a7/882389/badge.svg)](https://semaphoreci.com/peter-fogg/dotcom)

# DotCom

The new face of http://mbta.com/

## Getting Started

1. Install Erlang/Elixir: http://elixir-lang.org/install.html
1. Install NodeJS: https://nodejs.org/en/download/
1. Install Sass: `gem install sass`
  * You might get a permission error here.  You can either `sudo gem install sass`, or install a Ruby environment manager.
1. Install Phoenix: http://www.phoenixframework.org/docs/installation
1. Install our Elixir dependencies: `mix deps.get`
1. Install our Node dependencies: `cd apps/site && npm install`
1. Get a Font Awesome embed code at: http://fontawesome.io/get-started/
  * Once you've gotten your embed code, set the `FONT_AWESOME_ID` environment variable to that value.

## Running the Server

    mix phoenix.server

Then, visit the site at http://localhost:4000/

## Running the tests

    mix test
    cd apps/site; npm test  # runs the JS tests

## Building/deploying

1. Install Docker: https://docs.docker.com/engine/installation/
1. Build the .ZIP package: `sh build.sh`
  * This will build the release in a Docker container, and put the files in `site-build.zip`
1. Upload .ZIP package to Elastic Beanstalk
