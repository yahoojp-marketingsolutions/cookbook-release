CookbookRelease
===============

Helper to release cookbooks. This motivation is to publish new version at each commit on master branch from the CI.

This helper will create tags, push them and publish to supermarket.

Usage
-----

Include cookbook-release into your `Gemfile`.

Require cookbook-release into the `metadata.rb` file and replace the version by the helper:

```
version          Release.current_version
```

Include the rake tasks in your Rakefile:

```
require 'cookbook-release'
CookbookRelease::Rake::CookbookTask.new
```

Then you can publish on your supermarket using:

```
export SUPERMARKET_CLIENTKEYFILE=/tmp/my_key.pem
export SUPERMARKET_USERID=my_username
export SUPERMARKET_URL="http://supermarket.chef.io/api/v1/cookbooks"
export NO_PROMPT=""
rake release!
```

Note: this setup is intended to be used in a CI system such as jenkins or travis.
