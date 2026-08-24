require "integration_helper"

# These talk to the real community site rather than the local chef-zero.
RSpec.describe "installing from the community site", type: :aruba do
  it "installs a cookbook that exists" do
    write_community_berksfile("cookbook 'apache2', '1.6.6'")

    berks! "install"

    expect_output("Installing apache2 (1.6.6)")
    expect_stored_cookbooks(%w{apache2 1.6.6})
  end

  it "fails for a cookbook that does not exist" do
    write_community_berksfile("cookbook '1234567890'")

    berks "install"

    expect_output("Unable to find a solution for demands: 1234567890 (>= 0.0.0)")
    expect_exit_status(Berkshelf::NoSolutionError)
  end

  it "fails for a version that does not exist" do
    write_community_berksfile("cookbook 'apache2', '0.0.0'")

    berks "install"

    expect_output("Unable to find a solution for demands: apache2 (= 0.0.0)")
    expect_exit_status(Berkshelf::NoSolutionError)
  end
end
