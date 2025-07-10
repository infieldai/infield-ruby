# What is this gem for?

Maintainers use deprecation warnings to inform developers about breaking changes coming in new versions. To make these warnings actionable you need to monitor for them. This gem takes care of aggregating these warnings from any environment and sending them to the Infield API. Within Infield you can see all deprecations being thrown and verify once they've been fixed.

This differs from local-only tools like deprecation_toolkit in that warnings are sent up to a cloud-hosted API rather than stored in files locally. This makes it possible to profile for deprecations not just in dev/test but staging and production too.

`infield` supports warnings coming from gems and Ruby itself.

## Setup

You'll need an API key and repo environment ID to use this gem. You can find these at https://app.infield.ai/deprecations after signing up.

Add the gem to your gemfile:

    gem 'infield', require: false

Then in `config/application.rb`:

    if ENV['INFIELD_API_KEY']
      require 'infield'
      Infield.run(api_key: ENV['INFIELD_API_KEY'],
                  repo_environment_id: ENV['INFIELD_REPO_ENVIRONMENT_ID'])
    end

Only call `Infield.run` in environments that you want deprecation warnings to print for, since it will bypass configurations such as `config.active_support.report_deprecations = false`
and `config.active_support.deprecation = :silence`

## Configuration options

The infield gem batches requests and sends them asyncronously. You can configure the following options to `Infield.run` (defaults shown here):

    Infield.run(
        api_key: key, # required
        repo_environment_id: id, # required
        sleep_interval: 5, # seconds, # how long to sleep between processing events
        batch_size: 10, # how many events to batch in one API request to Infield
        queue_limit: 30 # If more than this number of events come in in sleep_interval, any over are dropped
    )

## Test environment notes

If you enable this gem in test and use another gem to block all web
calls in your test environment, make sure to allow access to `app.infield.ai`.
