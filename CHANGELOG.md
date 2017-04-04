# 0.3.1 (April 4, 2017)

## Bugfixes

* Support Structs in Params, e.g. File Uploads with `Plug.Upload`

# 0.3.0 (March 27, 2017)

## Features

* Filter out specific parameters before sending to bugsnag in `Bugsnex.Plug`, defaulting to password, password_confirmation and api_key

## Bugfixes

* Report hostname as String/Binary instead of charlist

# 0.2.1 (February 20, 2017)

## Bugfixes

* Remove a regression that made it impossible to send keyword lists to Bugsnex.put_metadata

# 0.2.0 (February 20, 2017)

## Features

* report the hostname

# 0.1.0 (January 24, 2017)

## Bugfixes

* Allow newer poison versions
* Remove Elixir 1.4 compilation warnings
