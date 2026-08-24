require_relative "support/test_keys"

def windows?
  !!(RUBY_PLATFORM =~ /mswin|mingw|windows/)
end

BERKS_SPEC_DATA = File.expand_path("data", __dir__)

require "rspec"
require "cleanroom/rspec"
require "webmock/rspec"
require "rspec/its"

Dir["spec/support/**/*.rb"].each { |f| require File.expand_path(f) }

RSpec.configure do |config|
  config.include Berkshelf::RSpec::FileSystemMatchers
  config.include Berkshelf::RSpec::ChefAPI
  config.include Berkshelf::RSpec::ChefServer
  config.include Berkshelf::RSpec::Git
  config.include Berkshelf::RSpec::PathHelpers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Verify partial doubles, so stubbing a method the real object does not have
  # is an error rather than a test that quietly asserts a fiction.
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run focus: true
  config.filter_run_excluding not_supported_on_windows: windows?
  config.run_all_when_everything_filtered = true

  # Fail on deprecated RSpec usage instead of printing a warning nobody reads.
  config.raise_errors_for_deprecations!

  # Records pass/fail per example so `rspec --only-failures` works.
  config.example_status_persistence_file_path = "spec/.examples.txt"

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Run examples in a random order so that one leaking state into another fails
  # visibly, instead of passing forever because the file order happens to hide
  # it. Seeding from config.seed keeps a failing order reproducible: the seed is
  # printed with the results and can be replayed with --seed.
  config.order = :random
  Kernel.srand config.seed

  config.before(:each) do
    Berkshelf.logger = Berkshelf::Logger.new(nil)
    Berkshelf.set_format(:null)
    Berkshelf.ui.mute!
  end

  config.before(:suite) do
    WebMock.disable_net_connect!(allow_localhost: false, net_http_connect_on_start: true)
    Berkshelf::RSpec::ChefServer.start
  end

  config.before(:all) do
    ENV["BERKSHELF_PATH"] = berkshelf_path.to_s
  end

  config.before(:each) do
    clean_tmp_path
    Berkshelf.initialize_filesystem
    Berkshelf::CookbookStore.instance.initialize_filesystem
    reload_configs
  end
end

def capture(stream)
  begin
    stream = stream.to_s
    eval "$#{stream} = StringIO.new"
    yield
    result = eval("$#{stream}").string
  ensure
    eval("$#{stream} = #{stream.upcase}")
  end

  result
end

require "berkshelf"

module Berkshelf
  class GitLocation
    include Berkshelf::RSpec::Git

    alias :real_clone :clone
    def clone
      fake_remote = generate_fake_git_remote(uri, tags: @branch ? [@branch] : [])
      @uri = "file://#{fake_remote}"
      real_clone
    end
  end
end
