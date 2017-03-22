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
