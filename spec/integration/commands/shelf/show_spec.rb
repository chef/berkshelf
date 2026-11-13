require "integration_helper"

RSpec.describe "berks shelf show", type: :aruba do
  it "fails when the cookbook is not in the store" do
    berks "shelf show fake"

    expect_output("Cookbook 'fake' not found in the Berkshelf shelf!")
    expect_exit_status(Berkshelf::CookbookNotFound)
  end

  it "shows every version of the named cookbook and nothing else" do
    store_cookbooks(%w{fake 1.0.0}, %w{ekaf 2.3.4})

    berks! "shelf show fake"

    expect_output("Displaying all versions of 'fake' in the Berkshelf shelf:\n        Name: fake\n     Version: 1.0.0\n     License: All rights reserved")
    expect_no_output("Name: ekaf")
  end

  it "shows a single version with --version" do
    store_cookbooks(%w{fake 1.0.0}, %w{ekaf 2.3.4})

    berks! "shelf show fake --version 1.0.0"

    expect_output("Displaying 'fake' (1.0.0) in the Berkshelf shelf:\n        Name: fake\n     Version: 1.0.0\n     License: All rights reserved")
    expect_no_output("Name: ekaf")
  end

  it "fails when the requested version is not in the store" do
    store_cookbooks(%w{fake 1.0.0}, %w{ekaf 2.3.4})

    berks "shelf show fake --version 1.2.3"

    expect_output("Cookbook 'fake' (1.2.3) not found in the Berkshelf shelf!")
    expect_exit_status(Berkshelf::CookbookNotFound)
  end

  it "lists every installed version in order" do
    store_cookbooks(%w{fake 1.0.0}, %w{fake 1.1.0}, %w{fake 1.2.0}, %w{fake 2.0.0})

    berks! "shelf show fake"

    expect_output(<<~OUTPUT.chomp)
      Displaying all versions of 'fake' in the Berkshelf shelf:
              Name: fake
           Version: 1.0.0
           License: All rights reserved

              Name: fake
           Version: 1.1.0
           License: All rights reserved

              Name: fake
           Version: 1.2.0
           License: All rights reserved

              Name: fake
           Version: 2.0.0
           License: All rights reserved
    OUTPUT
  end

  it "shows only the requested version when several are installed" do
    store_cookbooks(%w{fake 1.0.0}, %w{fake 1.1.0}, %w{fake 1.2.0}, %w{fake 2.0.0})

    berks! "shelf show fake --version 1.0.0"

    expect_output("Displaying 'fake' (1.0.0) in the Berkshelf shelf:\n        Name: fake\n     Version: 1.0.0\n     License: All rights reserved")
    expect_no_output(
      "        Name: fake\n     Version: 1.1.0\n     License: All rights reserved",
      "        Name: fake\n     Version: 1.2.0\n     License: All rights reserved",
      "        Name: fake\n     Version: 2.0.0\n     License: All rights reserved"
    )
  end
end
