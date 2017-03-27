# Bugsnex [![Hex Version](https://img.shields.io/hexpm/v/bugsnex.svg)](https://hex.pm/packages/bugsnex) [![Build Status](https://travis-ci.org/liefery/bugsnex.svg?branch=master)](https://travis-ci.org/liefery/bugsnex)

API client and logger for Bugsnag

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add bugsnex to your list of dependencies in `mix.exs`:

     ```elixir
     def deps do
       [{:bugsnex, "~> 0.2.1"}]
     end
     ```

  2. If you use Elixir < 1.4 ensure bugsnex is started before your application:

     ```elixir
     def application do
       [applications: [:bugsnex]]
     end
     ```

  3. Check out how to send notifications to bugsnag via `Bugsnag.notify` or the
     plug in the "Usage" section

## Configuration

```elixir
config :bugsnex, :otp_app, :your_app_name
config :bugsnex, :api_key, "your_api_key"
config :bugsnex, :release_stage, "staging"
config :bugsnex, :use_logger, true
config :bugsnex, :filter_params, ~w(password password_confirmation api_key)
```

The `:filter_params` config is used by the `Bugsnex.Plug` module to filter out
parameters that should not be sent to Bugsnag.

## Usage

### Sending bug reports

Once configured, use `Bugsnex.notice(exception)` or `Bugsnex.notice(exception,stacktrace)` to send errors to Bugsnag.

If `use_logger` is set to `true`, an [error logger](http://erlang.org/doc/man/error_logger.html) event handler is added
and [SASL](http://erlang.org/doc/apps/sasl/error_logging.html) compliant errors are sent to Bugsnag.

You can also manually wrap code in a `Bugsnex.handle_error` block. Errors in this block will then be sent to Bugsnag and reraised. Example:

```elixir
Bugsnex.handle_errors %{some: "metadata"} do
  somthing_that_could_raise_and_error()
end
```

### Automatic reports via Bugsnex.Plug

Bugsnex also provides a Plug called `Bugsnex.Plug` that you could add to
your router to send errors automatically. Example:

```elixir
defmodule YourApp.Router do
  use YourApp.Web, :router
  use Bugsnex.Plug

  # ...
end
```

### Tracking deployments

Use `Bugsnex.track_deploy(additional_params)` to send a deployment notification to bugsnag.
`additional_params` is an optional map with keys:

  * `:apiKey`: your bugsnag api key (default is `Application.get_env(:bugsnex, :api_key)`)
  * `:repository`: url of your source code repository (default is `Application.get_env(:bugsnex, :repository_url)`)
  * `:releaseStage`: the release stage (e.g. staging, production) (default is `Application.get_env(:bugsnex, :release_stage)`)
  * `:branch`: scm branch this release was deployed from
  * `:revision`: scm revision this release was deployed from
  * `:appVersion`: SemVer version of your app


### Metadata

You can associate metadata by calling `Bugsnex.put_metadata(%{some: "metadata"})`.
Note that metadata is stored inside the [process dictionary](http://www.erlang.org/course/advanced#dict).
This means that you shouldn't put a lot of data in there and also that it's only associated with the
calling process. Errors in different processes won't be associated with that metadata.

There are some special keys for metadata that Bugsnag understands (explanations paraphrased from the Bugsnag API documentation):

  * `%{user: %{id: 123, email: "user@example.com", name: "Some name"}`: Information about the user affected by the crash
  * `%{context: "auth/session#create"}`: A string representing what was happening in the application at the time of the error
  * `%{device: %{osVersion: "2.1.1", hostname: "web1.internal"}}`: Information about the computer/device running the app
