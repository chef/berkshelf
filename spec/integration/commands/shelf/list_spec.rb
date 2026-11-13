require "integration_helper"

RSpec.describe "berks shelf list", type: :aruba do
  it "reports an empty shelf" do
    berks! "shelf list"

    expect_output("There are no cookbooks in the Berkshelf shelf")
  end

  it "lists each cookbook in the store" do
    store_cookbooks(%w{fake 1.0.0}, %w{ekaf 2.3.4})

    berks! "shelf list"

    expect_output("Cookbooks in the Berkshelf shelf:\n  * ekaf (2.3.4)\n  * fake (1.0.0)")
  end

  it "groups multiple versions of one cookbook" do
    store_cookbooks(%w{fake 1.0.0}, %w{fake 1.1.0}, %w{fake 1.2.0}, %w{fake 2.0.0})

    berks! "shelf list"

    expect_output("Cookbooks in the Berkshelf shelf:\n  * fake (1.0.0, 1.1.0, 1.2.0, 2.0.0)")
  end
end
