require "integration_helper"

RSpec.describe "berks update", type: :aruba do
  before do
    store_cookbooks(
      %w{fake 0.1.0}, %w{fake 0.2.0}, %w{fake 1.0.0},
      %w{ekaf 1.0.0}, %w{ekaf 1.0.1}
    )
  end

  let(:two_cookbook_berksfile) { "cookbook 'ekaf', '~> 1.0.0'\ncookbook 'fake', '~> 0.1'" }
  let(:two_cookbook_lock) do
    <<~LOCK
      DEPENDENCIES
        ekaf (~> 1.0.0)
        fake (~> 0.1)

      GRAPH
        ekaf (1.0.0)
        fake (0.1.0)
    LOCK
  end

  it "updates every dependency when none is named" do
    write_berksfile(two_cookbook_berksfile)
    write_lockfile(two_cookbook_lock)

    berks! "update"

    expect_file_contains("Berksfile.lock", <<~LOCK.chomp)
      DEPENDENCIES
        ekaf (~> 1.0.0)
        fake (~> 0.1)

      GRAPH
        ekaf (1.0.1)
        fake (0.2.0)
    LOCK
  end

  it "updates only the named dependency" do
    write_berksfile(two_cookbook_berksfile)
    write_lockfile(two_cookbook_lock)

    berks! "update fake"

    expect_file_contains("Berksfile.lock", <<~LOCK.chomp)
      DEPENDENCIES
        ekaf (~> 1.0.0)
        fake (~> 0.1)

      GRAPH
        ekaf (1.0.0)
        fake (0.2.0)
    LOCK
  end

  it "updates a named transitive dependency" do
    store_cookbook_with_dependencies("seth", "1.0.0", [["fake", "~> 0.1"]])
    write_berksfile("cookbook 'seth', '1.0.0'")
    write_lockfile(<<~LOCK)
      DEPENDENCIES
        seth (= 1.0.0)

      GRAPH
        fake (0.1.0)
        seth (1.0.0)
          fake (~> 0.1)
    LOCK

    berks! "update fake"

    expect_file_contains("Berksfile.lock", <<~LOCK.chomp)
      DEPENDENCIES
        seth (= 1.0.0)

      GRAPH
        fake (0.2.0)
        seth (1.0.0)
          fake (~> 0.1)
    LOCK
  end

  it "updates a git location to the latest revision" do
    write_berksfile("cookbook 'berkshelf-cookbook-fixture', git: 'https://github.com/chef/berkshelf-cookbook-fixture'")
    write_lockfile(<<~LOCK)
      DEPENDENCIES
        berkshelf-cookbook-fixture
          git: https://github.com/chef/berkshelf-cookbook-fixture
          revision: 70a527e17d91f01f031204562460ad1c17f972ee

      GRAPH
        berkshelf-cookbook-fixture (0.2.0)
    LOCK

    berks! "install"
    berks! "update"

    expect_file_contains("Berksfile.lock", <<~LOCK.chomp)
      DEPENDENCIES
        berkshelf-cookbook-fixture
          git: https://github.com/chef/berkshelf-cookbook-fixture
          revision: eb7491b7dfcccc3236c86b23569e54d0c9f448eb

      GRAPH
        berkshelf-cookbook-fixture (1.0.0)
    LOCK
  end

  it "fails when the named cookbook is not a dependency" do
    write_berksfile("cookbook 'fake'")
    write_lockfile("DEPENDENCIES\n  fake\n\nGRAPH\n  fake (0.2.0)\n")

    berks "update not_real"

    expect_output("Dependency 'not_real' was not found. Please make sure it is in your Berksfile, and then run `berks install` to download and install the missing dependencies.")
    expect_exit_status(Berkshelf::DependencyNotFound)
  end
end
