# Background

The MBTA website includes a Drupal-based CMS backend for a lot of static content. Different teams at MBTA will have access to this CMS, with the idea that they'll be able to update whole pages or section of pages on the MBTA site without needing support from the dev team or to deploy an update to the site. The Drupal CMS exposes its data via a JSON API which the phoenix server pulls from as necessary. The location of the CMS is controlled by the `DRUPAL_ROOT` environment variable.

This `Content` app serves as a wrapper for that functionality.

We currently host the Drupal CMS with Pantheon (pantheon.io), and use it for content on the development and beta MBTA sites.

Local development is easiest with a copy of the Drupal CMS running locally, and the phoenix server pointing to it. Tooling makes this fairly straightforward to set up.

## Setup

* You'll need two accounts: one for Pantheon, the service which hosts the CMS, and one from within the CMS itself. Request these accounts from Paul Swartz.

* Download [kalabox](http://www.kalabox.io), a containerized way of developing Wordpress and Drupal sites. It has an integration with Pantheon to clone a pantheon site locally, which we'll use.

* Generate a Machine Token on Pantheon. This is how you will authenticate inside Kalabox. Once you're logged into pantheon.io, in the user account drop down on the top right, click "My Dashboard". Click "Account". Click "Machine Tokens". Click "Create token". Name it whatever you like. The token will only be displayed once, so copy it down somewhere.

* Now it's time to clone the production CMS locally. Open Kalabox. Click "Add new site". In the "Add Account" section, click "Pantheon" and add the token you generated above. This should sign you in and you should now see your account's email address at the bottom of the "Add Site" list. Click it and choose "mbta". Choose "mbta", "dev", and make sure "pull files" and "pull DB" are selected, then click Submit. This should pull (clone) the files and DB from the dev CMS on Pantheon, and set up a local Drupal CMS server running at mbta.kbox.site. (DNS should resolve that to 127.0.0.1.) You should be able to log in locally with your username and password from the other MBTA dev one, since it was cloned, users and encrypted passwords and all. You can't *create* a new account locally because the local CMS can't send emails.

* At any point you can "reset" your local copy to what's on production by going to Kalabox, clicking the gear associated with the mbta tile and click "Pull", pulling the database from dev and the files from dev.

* Ensure the CMS is set up by starting up your phoenix server pointing to it: `env DRUPAL_ROOT=http://mbta.kbox.site/ mix phoenix.server`. Visit localhost:4001/news/winter to confirm it loads.

## Code overview

Internally to the Drupal CMS, there are a number of custom "content types" created. For example, we created an "Event" content type, which has fields like "start_time", with drupal-primitive type "datetime". These content types are exposed to the world via a JSON REST API.

The `content` app provides internal Elixir types that match these Drupal content types. The aforementioned "event" content type is represented by `%Content.Event{}` in the elixir app. All of these types provide a `from_api/1` function that takes the parsed JSON from the Drupal API and returns elixir structs.

The `Content.Repo` module is the main interface the site uses to interact with the CMS. All the exposed endpoints on the CMS are wrapped by a function in `Content.Repo`. For example, the `/events` endpoint can be accessed via `Content.Repo.events/1`. All the `Content.Repo` functions return Elixir structs of the proper type.

For testing purposes, the `Content.Repo` implementation actually uses an environment-based `@cms_api` module, which exposes a single function `view/1`, which takes a URL path `view("/events")` and returns the parsed JSON result. That module contract is described by the `Content.CMS` behaviour. There are two modules that implement that interface. The first is `Content.CMS.HTTPClient` which actually hits the Drupal CMS at the path provided, and returns the result. The other implementing module is `Content.CMS.Static`, which the test environment uses and returns static JSON that has been saved in the `content/priv/` directory.

## CMS template language

The site supports some simple templating features to allow content creators in Drupal to embed things that we will interpret and embed in the content.

### Responsive data tables

The site will parse tables created with the Drupal table editor and rewrite and embed them in a way that our CSS will make responsive. To take advantage of this, the content creator needs to do two things:

1. In the Drupal table editor, indicate that one of the rows is a header row by choosing Headers -> First Row.
2. Provide text in the "Caption" input, which will be displayed as a table header in the mobile view.

### Font awesome icons

Font awesome icons are supported with the `{{ fa "rss" }}` syntax. Any string provided (`"rss"` in this example) will be passed  to our site's `fa()` view helper which will generate the appropriate `<i class="fa fa-rss">` markup.

### MBTA icons

Certain MBTA svg icons are supported via `{{ mbta-circle-icon "bus" }}` syntax. The currently supported list of icons is `"bus"`, `"commuter-rail"`, `"subway"`, and `"ferry"`.
