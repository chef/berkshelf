require "integration_helper"

RSpec.describe "berks shelf uninstall", type: :aruba do
  it "fails when the cookbook is not in the store" do
    berks "shelf uninstall fake"

    expect_output("Cookbook 'fake' not found in the Berkshelf shelf!")
    expect_exit_status(Berkshelf::CookbookNotFound)
  end

  it "removes only the named cookbook" do
    store_cookbooks(%w{fake 1.0.0}, %w{ekaf 2.3.4})

    berks! "shelf uninstall fake"

    expect_output("Successfully uninstalled fake (1.0.0)")
    expect_no_stored_cookbooks(%w{fake 1.0.0})
    expect_stored_cookbooks(%w{ekaf 2.3.4})
  end

  it "removes every version when no version is given" do
    store_cookbooks(%w{fake 1.0.0}, %w{fake 1.1.0}, %w{fake 1.2.0}, %w{fake 2.0.0})

    berks! "shelf uninstall fake"

    expect_output(
      "Successfully uninstalled fake (1.0.0)",
      "Successfully uninstalled fake (1.1.0)",
      "Successfully uninstalled fake (1.2.0)",
      "Successfully uninstalled fake (2.0.0)"
    )
    expect_no_stored_cookbooks(%w{fake 1.0.0}, %w{fake 1.1.0}, %w{fake 1.2.0}, %w{fake 2.0.0})
  end

  it "removes only the named version" do
    store_cookbooks(%w{fake 1.0.0}, %w{fake 1.1.0}, %w{fake 1.2.0}, %w{fake 2.0.0})

    berks! "shelf uninstall fake --version 1.0.0"

    expect_output("Successfully uninstalled fake (1.0.0)")
    expect_no_stored_cookbooks(%w{fake 1.0.0})
    expect_stored_cookbooks(%w{fake 1.1.0}, %w{fake 1.2.0}, %w{fake 2.0.0})
  end

  # Interactive, so this one spawns rather than running in-process.
  it "asks for confirmation when another cookbook depends on it", :spawn, not_supported_on_windows: true do
    store_cookbook_with_dependencies("fake", "1.0.0", [%w{ekaf 2.3.4}])
    store_cookbooks(%w{ekaf 2.3.4})

    run_command("berks shelf uninstall ekaf")
    type("yes")
    stop_all_commands

    expect_output("[fake (1.0.0)] depend on ekaf.\n\nAre you sure you want to continue? (y/N)")
    expect_output("Successfully uninstalled ekaf (2.3.4)")
    expect_no_stored_cookbooks(%w{ekaf 2.3.4})
  end

  it "skips the prompt with --force" do
    store_cookbook_with_dependencies("fake", "1.0.0", [%w{ekaf 2.3.4}])
    store_cookbooks(%w{ekaf 2.3.4})

    berks "shelf uninstall ekaf --force"

    expect_output("Successfully uninstalled ekaf (2.3.4)")
    expect_no_stored_cookbooks(%w{ekaf 2.3.4})
  end
end
