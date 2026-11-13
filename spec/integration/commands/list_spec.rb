require "integration_helper"

RSpec.describe "berks list", type: :aruba do
  it "lists the cookbooks installed by the Berksfile" do
    store_cookbooks(%w{fake1 1.0.0}, %w{fake2 1.0.1})
    write_berksfile("cookbook 'fake1', '1.0.0'\ncookbook 'fake2', '1.0.1'")
    write_lockfile(<<~LOCK)
      DEPENDENCIES
        fake1 (= 1.0.0)
        fake2 (= 1.0.1)

      GRAPH
        fake1 (1.0.0)
        fake2 (1.0.1)
    LOCK

    berks! "list"

    expect_output("Cookbooks installed by your Berksfile:\n  * fake1 (1.0.0)\n  * fake2 (1.0.1)")
  end

  it "requires a lockfile" do
    write_berksfile("cookbook 'fake', '1.0.0'")

    berks "list"

    expect_output("Lockfile not found! Run `berks install` to create the lockfile.")
    expect_exit_status(Berkshelf::LockfileNotFound)
  end

  it "detects a lockfile that is out of sync with the Berksfile" do
    write_berksfile("cookbook 'fake', '1.0.0'")
    write_lockfile("DEPENDENCIES\n\nGRAPH\n  not_fake (1.0.0)\n")

    berks "list"

    expect_output("The lockfile is out of sync! Run `berks install` to sync the lockfile.")
    expect_exit_status(Berkshelf::LockfileOutOfSync)
  end

  it "detects a locked dependency that is not installed" do
    write_berksfile("cookbook 'fake', '1.0.0'")
    write_lockfile("DEPENDENCIES\n  fake (= 1.0.0)\n\nGRAPH\n  fake (1.0.0)\n")

    berks "list"

    expect_output("The cookbook 'fake (1.0.0)' is not installed. Please run `berks install` to download and install the missing dependency.")
    expect_exit_status(Berkshelf::DependencyNotInstalled)
  end
end
