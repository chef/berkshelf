# Harness for the CLI integration specs, which drive the berks command through
# Aruba rather than calling library objects directly.
#
# This deliberately does not require spec_helper. The unit suite redirects
# GitLocation#clone to a local fixture remote and blocks localhost in WebMock;
# both are wrong here, where the point is to run the real command end to end.
# The two suites therefore run as separate RSpec processes -- see the spec and
# integration tasks in the Rakefile.

require "rspec"
require "rspec/its"
require "aruba/rspec"

def windows?
  !!(RUBY_PLATFORM =~ /mswin|mingw|windows/)
end

BERKS_SPEC_DATA = File.expand_path("data", __dir__)

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }
Dir[File.expand_path("integration/support/**/*.rb", __dir__)].sort.each { |f| require f }

require "berkshelf/cli"

# One chef-zero instance serves both the cookbook universe and the Chef server
# for these specs, so both names resolve to the same port.
CHEF_SERVER_PORT = Berkshelf::RSpec::ChefServer::PORT
BERKS_API_PORT   = CHEF_SERVER_PORT

RSpec.configure do |config|
  config.include Berkshelf::RSpec::PathHelpers
  config.include Berkshelf::RSpec::ChefAPI
  config.include Berkshelf::RSpec::ChefServer
  config.include Berkshelf::RSpec::FileSystemMatchers
  config.include Berkshelf::RSpec::Integration::CLI, type: :aruba

  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.mock_with :rspec

  config.raise_errors_for_deprecations!
  config.example_status_persistence_file_path = "spec/.integration_examples.txt"
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Ordering is fixed here, unlike the unit suite. These examples share one
  # chef-zero server and one cookbook store, and the reset between them is the
  # thing being relied on rather than something already proven.
  config.order = :defined

  config.before(:suite) { Berkshelf::RSpec::ChefServer.start(port: CHEF_SERVER_PORT) }
  config.after(:suite)  { Berkshelf::RSpec::ChefServer.stop }

  config.before(:each, type: :aruba) do
    # Aruba removes and recreates its working directory as each example sets up,
    # and its own hook runs ahead of this one. The in-process launcher leaves the
    # process inside that directory, so by the time we get here it can be sitting
    # on an unlinked path where any getcwd -- Dir.pwd, File.expand_path, or a
    # subprocess such as git -- fails with Errno::ENOENT.
    Dir.chdir(Berkshelf.root)

    aruba.config.command_launcher = :in_process
    aruba.config.main_class = Berkshelf::Cli::Runner
    aruba.config.io_wait_timeout = 5
    aruba.config.exit_timeout = 15

    Berkshelf.instance_variable_set(:@berkshelf_path, nil)
    ENV["BERKSHELF_PATH"] = berkshelf_path.to_s
    ENV["BERKSHELF_CONFIG"] = Berkshelf.config.path.to_s
    ENV["BERKSHELF_CHEF_CONFIG"] = chef_config_path.to_s

    clean_tmp_path
    Berkshelf.initialize_filesystem
    Berkshelf::CookbookStore.instance.initialize_filesystem
    reload_configs
    Berkshelf::CachedCookbook.instance_variable_set(:@loaded_cookbooks, nil)
    Berkshelf::RSpec::ChefServer.reset!
  end

  config.after(:each, type: :aruba) { Dir.chdir(Berkshelf.root) }
end
