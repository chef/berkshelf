# Berkshelf
[![Gem Version](https://img.shields.io/gem/v/berkshelf.svg)][gem]
[![CI Matrix Testing](https://github.com/chef/berkshelf/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/chef/berkshelf/actions/workflows/ci.yml?query=branch%3Amain)

[gem]: https://rubygems.org/gems/berkshelf

Manage Chef Infra cookbooks and cookbook dependencies

## Warning

Berkshelf is effectively deprecated. There is no ongoing maintenance and triage of issues. No active work is being done on bugfixes. The only
work being done is to maintain it so that it continues to ship and run in its existing state.

Existing users should strongly consider migrating to [Policyfiles](https://docs.chef.io/policyfile/) and new users should avoid using Berkshelf.

## Installation

Berkshelf is now included as part of the [Chef Workstation](https://downloads.chef.io/tools/workstation). This is fastest, easiest, and the recommended installation method for getting up and running with Berkshelf.

> note: You may need to uninstall the Berkshelf gem especially if you are using a Ruby version manager you may need to uninstall all Berkshelf gems from each Ruby installation.

### From Rubygems

If you are a developer or you prefer to install from Rubygems, we've got you covered.

Add Berkshelf to your repository's `Gemfile`:

```ruby
gem 'berkshelf'
```

Or run it as a standalone:

```shell
$ gem install berkshelf
```

## Usage

See [docs.chef.io](https://docs.chef.io/workstation/berkshelf/) for up-to-date usage instructions.

## CLI Usage

Berkshelf is intended to be used as a CLI tool.  It is not intended to be used as a library.  Other ruby code should shell out to the command line tool to use it.

## Supported Platforms

Berkshelf is tested and supported on Ruby 3.2 and later.

## Configuration

Berkshelf will search in specific locations for a configuration file. In order:

    $PWD/.berkshelf/config.json
    ~/.berkshelf/config.json

You are encouraged to keep project-specific configuration in the `$PWD/.berkshelf` directory. A default configuration file is generated for you, but you can update the values to suit your needs.

## Shell Completion

- [Bash](https://github.com/berkshelf/berkshelf-bash-plugin)
- [ZSH](https://github.com/berkshelf/berkshelf-zsh-plugin)

## Plugins

Please see [Plugins page](https://github.com/chef/berkshelf/blob/main/PLUGINS.md) for more information.

## Getting Help

* If you have an issue: report it on the [issue tracker](https://github.com/chef/berkshelf/issues)
* If you have a question: visit the #chef or #berkshelf channel on irc.freenode.net

## Authors

Thank you to all of our [Contributors](https://github.com/chef/berkshelf/graphs/contributors), testers, and users.

If you'd like to contribute, please see our [contribution guidelines](https://github.com/chef/berkshelf/blob/main/CONTRIBUTING.md) first.
# Contributing

## Developing

If you'd like to submit a patch:

1. Fork the project.
2. Make your feature addition or bug fix.
3. Add [tests](#testing) for it. This is important so that it isn't broken in a
   future version unintentionally.
4. Commit. **Do not touch any unrelated code, such as the gemspec or version.**
   If you must change unrelated code, do it in a commit by itself, so that it
   can be ignored.
5. Send a pull request.

## Testing

### Install prerequisites

Install git on your test system.

Install the latest version of [Bundler](https://bundler.io/)

    $ gem install bundler

Clone the project

    $ git clone https://github.com/chef/berkshelf.git

and run:

    $ cd berkshelf
    $ bundle install

Bundler will install all gems and their dependencies required for testing and developing.

### Running unit (RSpec) and acceptance (Cucumber) tests

We use Chef Zero - an in-memory Chef Server for running tests. It is automatically managed by the Specs and Cukes. Run:

    $ bundle exec guard start

or
   
    $ bundle exec thor spec:ci

See [here](https://github.com/tdegrunt/vagrant-chef-server-bootstrap) for a
quick way to get a testing chef server up.

### Debugging Issues
By default, Berkshelf will only give you the top-level output from a failed command. If you're working deep inside the core, an error like:

    Berkshelf Error: wrong number of arguments (2 for 1)

isn't exactly helpful...

Specify the `BERKSHELF_DEBUG` flag when running your command to see a full stack trace and other helpful debugging information.

## Releasing

Once you are ready to release Berkshelf, perform the following:

1. Update `CHANGELOG.md` with a new header indicating the version to be released
1. Examine the diff ([example](https://github.com/chef/berkshelf/compare/v8.0.2...main)) between main and the previous version.  Add all merged Pull Requests to the `CHANGELOG.md`
1. Update `version.rb` to the desired release version
1. Run `bundle update berkshelf`
1. Create a PR and review the `version.rb` changes and `CHANGELOG.md` changes
1. Once the PR is merged to main, run `rake release` on the main branch


# Copyright

See [COPYRIGHT.md](./COPYRIGHT.md).