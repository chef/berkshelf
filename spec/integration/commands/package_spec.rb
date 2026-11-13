require "integration_helper"

RSpec.describe "berks package", type: :aruba do
  before { store_cookbooks(%w{fake 1.0.0}) }

  it "packages the resolved cookbooks into a tarball" do
    write_berksfile("cookbook 'fake', '~> 1.0.0'")

    berks! "package my-cookbooks.tar.gz"

    expect(exist?("my-cookbooks.tar.gz")).to be(true)
    expect_output("Cookbook(s) packaged to")
    expect_archive_contents("my-cookbooks.tar.gz", <<~CONTENTS.chomp)
      cookbooks
      cookbooks/fake
      cookbooks/fake/attributes
      cookbooks/fake/attributes/default.rb
      cookbooks/fake/files
      cookbooks/fake/files/default
      cookbooks/fake/files/default/file.h
      cookbooks/fake/metadata.json
      cookbooks/fake/metadata.rb
      cookbooks/fake/recipes
      cookbooks/fake/recipes/default.rb
      cookbooks/fake/templates
      cookbooks/fake/templates/default
      cookbooks/fake/templates/default/template.erb
    CONTENTS
  end
end
