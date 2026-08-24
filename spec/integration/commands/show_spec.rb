require "integration_helper"

RSpec.describe "berks show", type: :aruba do
  it "prints the path of an installed dependency" do
    store_cookbooks(%w{fake 1.0.0})
    write_berksfile("cookbook 'fake', '1.0.0'")
    write_lockfile("DEPENDENCIES\n  fake (= 1.0.0)\n\nGRAPH\n  fake (1.0.0)\n")

    berks! "show fake"

    expect_output("cookbooks/fake-1.0.0")
  end

  it "prints the path of a transitive dependency" do
    store_cookbooks(%w{dep 1.0.0})
    store_cookbook_with_dependencies("fake", "1.0.0", [%w{dep ~>1.0.0}])
    write_berksfile("cookbook 'fake', '1.0.0'")
    write_lockfile(<<~LOCK)
      DEPENDENCIES
        fake (= 1.0.0)

      GRAPH
        dep (1.0.0)
        fake (1.0.0)
          dep (~> 1.0.0)
    LOCK

    berks! "install"
    berks! "show dep"

    expect_output("cookbooks/dep-1.0.0")
  end

  it "fails when the cookbook is not in the Berksfile" do
    write_berksfile

    berks "show fake"

    expect_output("Dependency 'fake' was not found. Please make sure it is in your Berksfile, and then run `berks install` to download and install the missing dependencies.")
    expect_exit_status(Berkshelf::DependencyNotFound)
  end

  it "fails when there is no lockfile" do
    write_berksfile("cookbook 'fake', '1.0.0'")

    berks "show fake"

    expect_output("Dependency 'fake' was not found. Please make sure it is in your Berksfile, and then run `berks install` to download and install the missing dependencies.")
    expect_exit_status(Berkshelf::DependencyNotFound)
  end

  it "fails when the locked cookbook is not in the store" do
    empty_cookbook_store
    write_berksfile("cookbook 'fake', '1.0.0'")
    write_lockfile("DEPENDENCIES\n  fake (= 1.0.0)\n\nGRAPH\n  fake (1.0.0)\n")

    berks "show fake"

    expect_output("Cookbook 'fake' (1.0.0) not found in the cookbook store!")
    expect_exit_status(Berkshelf::CookbookNotFound)
  end
end
