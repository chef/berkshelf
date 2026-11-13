require "spec_helper"

module Berkshelf
  describe ChefConfigCompat do
    subject { described_class.new(chef_config_path) }

    describe "delegating to ChefConfig::Config" do
      it "answers for settings it does not define itself" do
        expect(subject.node_name).to eq(ChefConfig::Config.node_name)
      end

      # respond_to_missing? is always invoked by Ruby with two arguments. A
      # one-argument definition still satisfies method_missing, so delegation
      # keeps working while every respond_to? call raises ArgumentError -- which
      # only shows up in code that duck-types the config rather than calling it.
      it "reports that it responds to delegated settings" do
        expect(subject.respond_to?(:node_name)).to be(true)
      end

      it "reports that it responds when private methods are included" do
        expect(subject.respond_to?(:node_name, true)).to be(true)
      end

      it "does not claim to respond to settings that do not exist" do
        expect(subject.respond_to?(:definitely_not_a_chef_setting)).to be(false)
      end
    end

    # These three exist purely to supply a default that ChefConfig::Config does
    # not carry, so a nil leaking through means cookbook metadata gets generated
    # with an empty field.
    #
    # They are set on the real config rather than stubbed: Mixlib::Config serves
    # these through method_missing, so they are not methods a verifying double
    # will accept a stub for.
    describe "defaults not present in ChefConfig::Config" do
      around do |example|
        saved = %i{cookbook_copyright cookbook_email cookbook_license}
          .to_h { |key| [key, ChefConfig::Config[key]] }
        example.run
        saved.each { |key, value| ChefConfig::Config[key] = value }
      end

      it "falls back to a placeholder copyright" do
        ChefConfig::Config[:cookbook_copyright] = nil
        expect(subject.cookbook_copyright).to eq("YOUR_NAME")
      end

      it "falls back to a placeholder email" do
        ChefConfig::Config[:cookbook_email] = nil
        expect(subject.cookbook_email).to eq("YOUR_EMAIL")
      end

      it "falls back to a reserved license" do
        ChefConfig::Config[:cookbook_license] = nil
        expect(subject.cookbook_license).to eq("reserved")
      end

      it "prefers a configured value over the fallback" do
        ChefConfig::Config[:cookbook_copyright] = "Someone Else"
        expect(subject.cookbook_copyright).to eq("Someone Else")
      end
    end
  end
end
