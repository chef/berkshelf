require "integration_helper"

RSpec.describe "berks apply", type: :aruba do
  it "locks a cookbook and its dependencies into the environment" do
    store_cookbook_with_dependencies("fake", "1.0.0", [%w{dependency 2.0.0}])
    store_cookbooks(%w{dependency 2.0.0})
    chef_server_has_environment("my_env")
    write_berksfile("cookbook 'fake', '1.0.0'")

    berks! "install"
    berks! "apply my_env"

    expect_environment_locks("my_env", "fake" => "= 1.0.0", "dependency" => "= 2.0.0")
  end

  it "fails when the environment does not exist" do
    chef_server_has_no_environment("my_env")
    store_cookbooks(%w{fake 1.0.0})
    write_berksfile("cookbook 'fake', '1.0.0'")

    berks! "install"
    berks "apply my_env"

    expect_output("The environment 'my_env' does not exist")
    expect_exit_status(Berkshelf::EnvironmentNotFound)
  end

  it "requires a lockfile" do
    berks "apply my_env"

    expect_output("Lockfile not found! Run `berks install` to create the lockfile.")
    expect_exit_status(Berkshelf::LockfileNotFound)
  end
end
