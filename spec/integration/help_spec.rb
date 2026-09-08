require "integration_helper"

RSpec.describe "berks help switches", type: :aruba do
  {
    "berks --help"          => "berks help",
    "berks -h"              => "berks help",
    "berks cookbook --help" => "berks help cookbook",
    "berks cookbook -h"     => "berks help cookbook",
    "berks shelf --help"    => "berks shelf help",
    "berks shelf -h"        => "berks shelf help",
  }.each do |switch, equivalent|
    it "`#{switch}` prints the same output as `#{equivalent}`" do
      run_command_and_stop(switch)
      switch_output = last_command_started.stdout
      run_command_and_stop(equivalent)

      expect(switch_output).to eql(last_command_started.stdout)
    end
  end
end
