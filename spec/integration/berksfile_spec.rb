require "integration_helper"

RSpec.describe "evaluating a Berksfile", type: :aruba do
  it "evaluates plain Ruby in the Berksfile" do
    write_file("Berksfile", <<~BERKSFILE)
      source 'https://supermarket.chef.io'

      if ENV['BACON']
        puts "If you don't got bacon..."
      else
        puts "No bacon :'("
      end
    BERKSFILE
    set_environment_variable("BACON", "1")

    berks! "install"

    expect_output("If you don't got bacon...")
  end

  it "refuses methods that are not part of the Berksfile DSL" do
    write_file("Berksfile", "add_location(:foo)")

    berks "install"

    expect_output_matching(/An error occurred while reading the Berksfile:\n\n\s+undefined method ['`]add_location['`] for #<.*>/m)
    expect_exit_status(Berkshelf::BerksfileReadError)
  end

  it "reports a Ruby error in the Berksfile" do
    write_file("Berksfile", 'ptus "This is a ruby syntax error"')

    berks "install"

    expect_output_matching(/An error occurred while reading the Berksfile:\n\n\s+undefined method ['`]ptus['`] for #<.*>/m)
    expect_exit_status(Berkshelf::BerksfileReadError)
  end
end
