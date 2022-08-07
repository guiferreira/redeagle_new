## mix redeagle.new

Provides `redeagle.new` installer as an archive.

To install from Hex, run:

    $ mix archive.install hex redeagle_new

To build and install it locally,
ensure any previous archive versions are removed:

    $ mix archive.uninstall redeagle_new

Then run:

    $ cd redeagle
    $ mix do archive.build, archive.install

## Creating a project with Phoenix + React + Docker:

    $ mix redeagle.new my_app
