def windows?
  !!(RUBY_PLATFORM =~ /mswin|mingw|windows/)
end

require "aruba/cucumber"
require "cucumber/rspec/doubles"

Dir["spec/support/**/*.rb"].each { |f| require File.expand_path(f) }

World(Berkshelf::RSpec::PathHelpers)

# these tests used to start a chef-zero server on one port, and a berks-api server on another port
# they now start a chef-zero server that supports the universe endpoint on one port.
#
# if there becomes a need to integration test talking to a supermarket/universe endpoint and then
# talking to a separate chef-server, then these features could be split back up again, but the
# Berkshelf::RSpec::ChefServer helper class would need to support managing multiple chef-zero servers.
CHEF_SERVER_PORT = 26310
BERKS_API_PORT   = 26310

at_exit do
  Berkshelf::RSpec::ChefServer.stop
end

Before do
  # Aruba removes and recreates its working directory as each scenario sets up,
  # and its own Before hook runs ahead of this one. The in-process launcher
  # leaves us sitting inside that directory, so by the time we get here the
  # process can be on an unlinked directory, where any getcwd -- Dir.pwd,
  # File.expand_path, or a subprocess such as git -- fails with Errno::ENOENT.
  # Step back out to a directory that always exists. The matching After hook
  # below keeps us out of it once the scenario is done.
  Dir.chdir(Berkshelf.root)

  # Legacy ENV variables until we can move over to all InProcess
  Berkshelf.instance_variable_set(:@berkshelf_path, nil)
  ENV["BERKSHELF_PATH"] = berkshelf_path.to_s
  ENV["BERKSHELF_CONFIG"] = Berkshelf.config.path.to_s
  ENV["BERKSHELF_CHEF_CONFIG"] = chef_config_path.to_s

  aruba.config.command_launcher = :in_process
  aruba.config.main_class = Berkshelf::Cli::Runner

  clean_tmp_path
  Berkshelf.initialize_filesystem
  Berkshelf::CookbookStore.instance.initialize_filesystem
  reload_configs
  Berkshelf::CachedCookbook.instance_variable_set(:@loaded_cookbooks, nil)

  # This appears to be dead code
  # endpoints = [
  #  {
  #    type: "chef_server",
  #    options: {
  #      url: "http://localhost:#{CHEF_SERVER_PORT}",
  #      client_name: "reset",
  #      client_key: File.expand_path("spec/config/berkshelf.pem"),
  #    },
  #  },
  # ]

  Berkshelf::RSpec::ChefServer.start(port: CHEF_SERVER_PORT)

  aruba.config.io_wait_timeout = Cucumber::JRUBY ? 7 : 5
  @aruba_timeout_seconds = Cucumber::JRUBY ? 35 : 15
end

# Aruba removes and recreates its working directory as each scenario sets up.
# The in-process launcher leaves us sitting inside that directory, so once it is
# unlinked any later getcwd -- Dir.pwd, File.expand_path, or a subprocess such as
# git -- fails with Errno::ENOENT. Step back out to a directory that always
# exists so the next scenario starts from a valid working directory.
After do
  Dir.chdir(Berkshelf.root)
end

Before("@spawn") do
  aruba.config.command_launcher = :spawn

  Berkshelf.instance_variable_set(:@berkshelf_path, nil)
  set_environment_variable("BERKSHELF_PATH", berkshelf_path.to_s)
  set_environment_variable("BERKSHELF_CONFIG", Berkshelf.config.path.to_s)
  set_environment_variable("BERKSHELF_CHEF_CONFIG", chef_config_path.to_s)
end

Before("@slow_process") do
  aruba.config.io_wait_timeout = Cucumber::JRUBY ? 70 : 30
  @aruba_timeout_seconds = Cucumber::JRUBY ? 140 : 60
end

# Skip scenarios that require the dep_selector gem (optional dependency)
Before("@requires_dep_selector") do
  Gem::Specification.find_by_name("dep_selector")
rescue Gem::MissingSpecError
  skip_this_scenario("dep_selector gem is not installed (optional dependency)")
end

require "berkshelf/cli"
