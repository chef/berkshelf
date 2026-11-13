require "integration_helper"

RSpec.describe "berks search", type: :aruba do
  it "finds a cookbook by name" do
    berks! "search berkshelf-cookbook-fixture"

    expect_output("berkshelf-cookbook-fixture (1.0.0)")
  end

  it "finds cookbooks by partial name" do
    berks! "search berkshelf-"

    expect_output(
      "berkshelf-api (1.2.2)",
      "berkshelf-api-server (2.2.0)",
      "berkshelf-cookbook-fixture (1.0.0)"
    )
    berks_stdout.split("\n").each { |line| expect(line).to start_with("berkshelf-") }
  end
end
