require "integration_helper"

RSpec.describe "berks verify", type: :aruba do
  before do
    create_cookbook("sparkle_motion")
    cd("sparkle_motion")
    write_berksfile("metadata")
  end

  it "tells the user to run berks install when there is no lockfile" do
    berks "verify"

    expect_output("Lockfile not found! Run `berks install` to create the lockfile.")
    expect_exit_status(Berkshelf::LockfileNotFound)
  end

  it "reports the cookbook as verified when a valid lockfile is present" do
    berks! "install"
    berks! "verify"

    expect_output("Verifying (1) cookbook(s)...", "Verified.")
  end
end
