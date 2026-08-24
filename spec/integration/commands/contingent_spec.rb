require "integration_helper"

RSpec.describe "berks contingent", type: :aruba do
  before { empty_cookbook_store }

  it "lists the cookbooks that depend on the named cookbook" do
    store_cookbooks(%w{dep 1.0.0})
    store_cookbook_with_dependencies("fake", "1.0.0", [%w{dep ~>1.0.0}])
    store_cookbook_with_dependencies("ekaf", "1.0.0", [%w{dep ~>1.0.0}])
    write_berksfile("cookbook 'fake', '1.0.0'\ncookbook 'ekaf', '1.0.0'")

    berks "install"
    berks! "contingent dep"

    expect_output("Cookbooks in this Berksfile contingent upon 'dep':\n  * ekaf (1.0.0)\n  * fake (1.0.0)")
  end

  it "reports when nothing depends on the cookbook" do
    store_cookbooks(%w{fake 1.0.0})
    write_berksfile("cookbook 'fake', '1.0.0'")

    berks "install"
    berks! "contingent dep"

    expect_output("There are no cookbooks in this Berksfile contingent upon 'dep'.")
  end

  it "reports when the cookbook is not in the Berksfile at all" do
    write_berksfile

    berks! "contingent dep"

    expect_output("There are no cookbooks in this Berksfile contingent upon 'dep'.")
  end
end
